"""
DAG: hh_vacancy_details

Загружает детали вакансий по API GET /vacancies/{id} только для вакансий из view raw.vacancies_for_details
(роли: программист, разработчик, аналитик, разработ). Дельта: только id, которых ещё нет в vacancy_details_loaded.
Один запрос раз в 10 с; при 403 — ожидание 1 мин, повтор; при повторной 403 — 5 мин, повтор.
При таймауте/SSL/ConnectionError — ожидание 1 мин, затем 5 мин, ретраи (DAG не падает, вакансия пропускается после 3 попыток).
После успеха после бэкоффа — интервал 1 мин. Каждый успешный ответ сразу пишем в БД.
DAG работает 2 часа, затем завершается без повторных попыток.
"""
from __future__ import annotations

import json
import logging
import time
from datetime import datetime

import requests
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook

DEFAULT_CONN_ID = "pg_conn"
VACANCY_DETAIL_URL = "https://api.hh.ru/vacancies"
RUN_DURATION_S = 24 * 3600  # 24 часа
NORMAL_INTERVAL_S = 10
BACKOFF_1MIN_S = 60
BACKOFF_5MIN_S = 300
SLOW_INTERVAL_S = 60  # после успеха после бэкоффа
REQUEST_TIMEOUT_S = 60  # таймаут одного запроса (увеличен для медленной сети)
# При таймауте/SSL/ConnectionError: ждём и повторяем, DAG не падает
NETWORK_RETRY_WAIT_S = 60
NETWORK_RETRY_WAIT_LONG_S = 300
NETWORK_RETRIES = 3


def _get_response(url: str, vacancy_id: str) -> requests.Response | None:
    """Запрос к API с ретраями при таймауте/SSL/ConnectionError. При неудаче после всех попыток — None (даг не падает)."""
    retryable = (
        requests.exceptions.Timeout,
        requests.exceptions.SSLError,
        requests.exceptions.ConnectionError,
    )
    for attempt in range(NETWORK_RETRIES):
        try:
            return requests.get(url, timeout=REQUEST_TIMEOUT_S)
        except retryable as e:
            if attempt == NETWORK_RETRIES - 1:
                logging.warning("Vacancy %s: %s after %s attempts, skip", vacancy_id, e, NETWORK_RETRIES)
                return None
            wait = NETWORK_RETRY_WAIT_S if attempt == 0 else NETWORK_RETRY_WAIT_LONG_S
            logging.warning("Vacancy %s: %s, wait %ss and retry (%s/%s)", vacancy_id, e, wait, attempt + 1, NETWORK_RETRIES)
            time.sleep(wait)
    return None


def _fetch_and_save_vacancy_details(conn_id: str = DEFAULT_CONN_ID) -> None:
    """Цикл до 2 ч: to_load без уже загруженных, 1 запрос / 10 с, при 403 — бэкофф, при таймауте/SSL — ретраи, успех — сразу вставка в БД."""
    hook = PostgresHook(postgres_conn_id=conn_id)
    conn = hook.get_conn()
    cur = conn.cursor()
    cur.execute(
        """
        SELECT DISTINCT v.id
        FROM raw.vacancies_for_details v
        LEFT JOIN raw.vacancy_details_loaded l ON v.id = l.vacancy_id
        WHERE l.vacancy_id IS NULL
        ORDER BY v.id
        """
    )
    to_load = [r[0] for r in cur.fetchall()]
    cur.close()
    conn.close()

    if not to_load:
        logging.info("No vacancies to load (all already in vacancy_details_loaded)")
        return

    logging.info("To load: %d vacancies, run up to %s seconds", len(to_load), RUN_DURATION_S)
    start = time.monotonic()
    current_interval = NORMAL_INTERVAL_S
    loaded_ids = []

    for vid in to_load:
        if time.monotonic() - start >= RUN_DURATION_S:
            logging.info(f"Reached {RUN_DURATION_S/3600} hours, stopping. Loaded %d vacancies in this run.", len(loaded_ids))
            break

        url = f"{VACANCY_DETAIL_URL}/{vid}?host=hh.ru"
        response = _get_response(url, vid)
        if response is None:
            time.sleep(current_interval)
            continue

        if response.status_code == 200:
            _insert_one(hook, vid, response.json())
            loaded_ids.append(vid)
            #logging.info("Loaded vacancy id=%s (total this run: %d)", vid, len(loaded_ids))
            time.sleep(current_interval)
            continue

        if response.status_code == 403:
            logging.warning("Vacancy %s: HTTP 403, wait 1 min and retry", vid)
            time.sleep(BACKOFF_1MIN_S)
            if time.monotonic() - start >= RUN_DURATION_S:
                break
            response2 = _get_response(url, vid)
            if response2 is None:
                time.sleep(current_interval)
                continue
            if response2.status_code == 200:
                _insert_one(hook, vid, response2.json())
                loaded_ids.append(vid)
                current_interval = SLOW_INTERVAL_S
                logging.info("Loaded vacancy id=%s after 1 min backoff, interval now 1 min", vid)
                time.sleep(current_interval)
                continue
            if response2.status_code == 403:
                logging.warning("Vacancy %s: HTTP 403 again, wait 5 min and retry", vid)
                time.sleep(BACKOFF_5MIN_S)
                if time.monotonic() - start >= RUN_DURATION_S:
                    break
                response3 = _get_response(url, vid)
                if response3 is None:
                    time.sleep(current_interval)
                    continue
                if response3.status_code == 200:
                    _insert_one(hook, vid, response3.json())
                    loaded_ids.append(vid)
                    current_interval = SLOW_INTERVAL_S
                    logging.info("Loaded vacancy id=%s after 5 min backoff, interval now 1 min", vid)
                    time.sleep(current_interval)
                    continue
                logging.warning("Vacancy %s: still HTTP %s after 5 min backoff, skip", vid, response3.status_code)
            else:
                logging.warning("Vacancy %s: HTTP %s on retry, skip", vid, response2.status_code)
        else:
            logging.warning("Vacancy %s: HTTP %s, skip", vid, response.status_code)

        time.sleep(current_interval)

    logging.info("Finished. Loaded vacancy ids in this run: %s", loaded_ids)


def _insert_one(hook: PostgresHook, vacancy_id: str, data: dict) -> None:
    """Одна вставка в raw.vacancy_details и raw.vacancy_details_loaded."""
    vid = data.get("id") or vacancy_id
    payload_str = json.dumps(data, ensure_ascii=False)
    conn = hook.get_conn()
    cur = conn.cursor()
    try:
        cur.execute(
            """
            INSERT INTO raw.vacancy_details (id, payload, inserted_at)
            VALUES (%s, %s::jsonb, now())
            ON CONFLICT (id) DO UPDATE SET payload = EXCLUDED.payload, inserted_at = now()
            """,
            (vid, payload_str),
        )
        cur.execute(
            """
            INSERT INTO raw.vacancy_details_loaded (vacancy_id, loaded_at)
            VALUES (%s, now())
            ON CONFLICT (vacancy_id) DO UPDATE SET loaded_at = now()
            """,
            (vid,),
        )
        conn.commit()
    finally:
        cur.close()
        conn.close()


with DAG(
    dag_id="hh_vacancy_details",
    start_date=datetime(2026, 3, 1),
    schedule_interval=None,
    catchup=False,
    max_active_runs=1,
    tags=["ingestion", "hh", "vacancy_details"],
) as dag:

    PythonOperator(
        task_id="load_vacancy_details",
        python_callable=_fetch_and_save_vacancy_details,
        op_kwargs={"conn_id": DEFAULT_CONN_ID},
    )
