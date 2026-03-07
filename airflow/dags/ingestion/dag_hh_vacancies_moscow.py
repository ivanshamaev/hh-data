"""
DAG: hh_vacancies_moscow

Загружает вакансии HH.ru по Москве для каждой профессиональной роли из raw.roles.
Роли берутся из БД (без запросов к api.hh.ru/professional_roles).
Данные: исходный JSON в payload + распарсенные поля для обозначения. Обработка — Polars.

Требуется Airflow Variable: token (Bearer-токен HH.ru).
Опционально: client_id, client_secret; hh_user_agent (по умолчанию hh_data/1.0).
"""
from __future__ import annotations

import logging
import time
from datetime import datetime

from airflow import DAG
from airflow.decorators import task
from airflow.models import Variable
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook

DEFAULT_CONN_ID = "pg_conn"
VACANCIES_URL = "https://api.hh.ru/vacancies"
AREA_MOSCOW = 1
PER_PAGE = 100
REQUEST_DELAY_S = 0.2
REQUEST_RETRIES = 4
REQUEST_RETRY_DELAY_S = 3


def _normalize_vacancy(v: dict, professional_role_id: str) -> dict:
    """Извлекает поля для обозначения вакансии из сырого объекта."""
    salary = v.get("salary") or {}
    area = v.get("area") or {}
    employer = v.get("employer") or {}
    type_ = v.get("type") or {}
    logo_urls = employer.get("logo_urls") or {}
    return {
        "id": v.get("id"),
        "professional_role_id": professional_role_id,
        "payload": v,
        "name": v.get("name"),
        "area_name": area.get("name"),
        "salary_from": salary.get("from"),
        "salary_to": salary.get("to"),
        "currency": salary.get("currency"),
        "published_at": v.get("published_at"),
        "employer_id": employer.get("id"),
        "employer_name": employer.get("name"),
        "alternate_url": v.get("alternate_url"),
        "type_id": type_.get("id"),
        "type_name": type_.get("name"),
        "vacancy_url": v.get("url"),
        "employer_url": employer.get("url"),
        "employer_logo_urls_240": logo_urls.get("240"),
    }


def _fetch_and_insert_vacancies_for_role(
    role_id: str,
    conn_id: str = DEFAULT_CONN_ID,
    **kwargs,
) -> None:
    """Для одной роли: запрос к API по страницам, разбор через Polars, вставка в raw.vacancies."""
    import json

    import polars as pl
    import requests

    try:
        token = Variable.get("token")
    except KeyError:
        raise ValueError(
            "Variable 'token' is not set. "
            "Add it in Airflow: Admin → Variables (Bearer token HH.ru)."
        ) from None
    if not token or not str(token).strip():
        raise ValueError("Variable 'token' is empty. Set your HH.ru API token.")
    user_agent = Variable.get("hh_user_agent", default_var="hh_data/1.0")
    headers = {
        "Authorization": f"Bearer {token}",
        "HH-User-Agent": user_agent,
    }

    def _get_page(params: dict):
        for attempt in range(REQUEST_RETRIES):
            try:
                r = requests.get(
                    VACANCIES_URL, headers=headers, params=params, timeout=30
                )
                r.raise_for_status()
                return r.json()
            except (requests.exceptions.SSLError, requests.exceptions.ConnectionError) as e:
                if attempt == REQUEST_RETRIES - 1:
                    raise
                logging.warning(
                    "Role %s page %s: %s, retry %s/%s in %ss",
                    role_id, params.get("page"), e, attempt + 1, REQUEST_RETRIES, REQUEST_RETRY_DELAY_S,
                )
                time.sleep(REQUEST_RETRY_DELAY_S)
        raise RuntimeError("Unreachable")

    all_items = []
    page = 0
    while True:
        params = {
            "professional_role": role_id,
            "area": AREA_MOSCOW,
            "per_page": PER_PAGE,
            "page": page,
        }
        data = _get_page(params)
        items = data.get("items") or []
        if not items:
            break
        all_items.extend(items)
        pages = data.get("pages", 0)
        if page >= pages - 1:
            break
        page += 1
        time.sleep(REQUEST_DELAY_S)

    if not all_items:
        logging.info("Role %s: 0 vacancies, nothing to merge", role_id)
        return

    rows = [_normalize_vacancy(v, role_id) for v in all_items]
    # payload как dict для JSONB; в БД передаём сериализованный JSON
    for r in rows:
        r["payload_json"] = json.dumps(r.pop("payload"), ensure_ascii=False)

    df = pl.from_dicts(rows, schema_overrides={"id": pl.String, "professional_role_id": pl.String})

    hook = PostgresHook(postgres_conn_id=conn_id)
    conn = hook.get_conn()
    cur = conn.cursor()
    merge_sql = """
        INSERT INTO raw.vacancies (
            id, professional_role_id, payload,
            name, area_name, salary_from, salary_to, currency, published_at,
            employer_id, employer_name, alternate_url, type_id, type_name,
            vacancy_url, employer_url, employer_logo_urls_240, inserted_at
        )
        VALUES (%s, %s, %s::jsonb, %s, %s, %s, %s, %s, %s::timestamptz, %s, %s, %s, %s, %s, %s, %s, %s, now())
        ON CONFLICT (id, professional_role_id) DO UPDATE SET
            payload = EXCLUDED.payload,
            name = EXCLUDED.name,
            area_name = EXCLUDED.area_name,
            salary_from = EXCLUDED.salary_from,
            salary_to = EXCLUDED.salary_to,
            currency = EXCLUDED.currency,
            published_at = EXCLUDED.published_at,
            employer_id = EXCLUDED.employer_id,
            employer_name = EXCLUDED.employer_name,
            alternate_url = EXCLUDED.alternate_url,
            type_id = EXCLUDED.type_id,
            type_name = EXCLUDED.type_name,
            vacancy_url = EXCLUDED.vacancy_url,
            employer_url = EXCLUDED.employer_url,
            employer_logo_urls_240 = EXCLUDED.employer_logo_urls_240
    """
    try:
        for row in df.iter_rows(named=True):
            cur.execute(
                merge_sql,
                (
                    row["id"],
                    row["professional_role_id"],
                    row["payload_json"],
                    row["name"],
                    row["area_name"],
                    row["salary_from"],
                    row["salary_to"],
                    row["currency"],
                    row["published_at"],
                    row["employer_id"],
                    row["employer_name"],
                    row["alternate_url"],
                    row["type_id"],
                    row["type_name"],
                    row["vacancy_url"],
                    row["employer_url"],
                    row["employer_logo_urls_240"],
                ),
            )
        conn.commit()
    finally:
        cur.close()
        conn.close()

    logging.info("Role %s: merged %d vacancies", role_id, len(df))


@task
def get_role_ids(conn_id: str = DEFAULT_CONN_ID) -> list[dict[str, str]]:
    """Читает из raw.roles список уникальных role id для mapped task."""
    hook = PostgresHook(postgres_conn_id=conn_id)
    conn = hook.get_conn()
    cur = conn.cursor()
    try:
        cur.execute("SELECT DISTINCT id FROM raw.roles ORDER BY id")
        rows = cur.fetchall()
        return [{"role_id": r[0], "conn_id": DEFAULT_CONN_ID} for r in rows]
    finally:
        cur.close()
        conn.close()


with DAG(
    dag_id="hh_vacancies_moscow",
    start_date=datetime(2026, 3, 1),
    schedule_interval=None,
    catchup=False,
    max_active_runs=1,
    tags=["ingestion", "hh", "vacancies", "moscow"],
) as dag:

    role_ids = get_role_ids()

    load_vacancies = PythonOperator.partial(
        task_id="load_vacancies_by_role",
        python_callable=_fetch_and_insert_vacancies_for_role,
        max_active_tis_per_dag=10,
    ).expand(op_kwargs=role_ids)

    role_ids >> load_vacancies
