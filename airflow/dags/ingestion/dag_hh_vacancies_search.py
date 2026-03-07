"""
DAG: hh_vacancies_search

Загружает вакансии HH.ru по ключевым фразам (параметр text). Merge в raw.vacancies_search.
Обработка через Polars. Тот же подход, что по городам: insert + update при конфликте.
"""
from __future__ import annotations

import json
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
PER_PAGE = 100
REQUEST_DELAY_S = 0.2
REQUEST_RETRIES = 4
REQUEST_RETRY_DELAY_S = 3

SEARCH_QUERIES = [
    "data engineer",
    "инженер данных",
    "разработчик dwh",
    "bi разработчик",
    "Data-инженер",
    "Team Lead DWH",
    "Разработчик витрины",
    "Архитектор данных",
    "Lead Data Engineer",
    "ML Engineer",
    "pyspark",
    "trino",
    "Vertica",
]


def _normalize_vacancy_search(v: dict, search_query: str) -> dict:
    """Извлекает поля для обозначения вакансии; search_query вместо professional_role_id."""
    salary = v.get("salary") or {}
    area = v.get("area") or {}
    employer = v.get("employer") or {}
    type_ = v.get("type") or {}
    logo_urls = employer.get("logo_urls") or {}
    return {
        "id": v.get("id"),
        "search_query": search_query,
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


def _fetch_and_merge_vacancies_for_query(
    search_query: str,
    conn_id: str = DEFAULT_CONN_ID,
    **kwargs,
) -> None:
    """Для одной фразы: запрос по страницам, разбор через Polars, merge в raw.vacancies_search."""
    import polars as pl
    import requests

    try:
        token = Variable.get("token")
    except KeyError:
        raise ValueError(
            "Variable 'token' is not set. Add it in Airflow: Admin → Variables (Bearer token HH.ru)."
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
                    "Query %r page %s: %s, retry %s/%s in %ss",
                    search_query, params.get("page"), e, attempt + 1, REQUEST_RETRIES, REQUEST_RETRY_DELAY_S,
                )
                time.sleep(REQUEST_RETRY_DELAY_S)
        raise RuntimeError("Unreachable")

    all_items = []
    page = 0
    while True:
        params = {
            "text": search_query,
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
        logging.info("Query %r: 0 vacancies, nothing to merge", search_query)
        return

    rows = [_normalize_vacancy_search(v, search_query) for v in all_items]
    for r in rows:
        r["payload_json"] = json.dumps(r.pop("payload"), ensure_ascii=False)

    df = pl.from_dicts(
        rows,
        schema_overrides={"id": pl.String, "search_query": pl.String},
    )

    hook = PostgresHook(postgres_conn_id=conn_id)
    conn = hook.get_conn()
    cur = conn.cursor()
    merge_sql = """
        INSERT INTO raw.vacancies_search (
            id, search_query, payload,
            name, area_name, salary_from, salary_to, currency, published_at,
            employer_id, employer_name, alternate_url, type_id, type_name,
            vacancy_url, employer_url, employer_logo_urls_240, inserted_at
        )
        VALUES (%s, %s, %s::jsonb, %s, %s, %s, %s, %s, %s::timestamptz, %s, %s, %s, %s, %s, %s, %s, %s, now())
        ON CONFLICT (id, search_query) DO UPDATE SET
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
                    row["search_query"],
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

    logging.info("Query %r: merged %d vacancies", search_query, len(df))


@task
def get_search_queries() -> list[dict[str, str]]:
    """Список запросов для mapped task (можно заменить на Variable при необходимости)."""
    return [
        {"search_query": q, "conn_id": DEFAULT_CONN_ID}
        for q in SEARCH_QUERIES
    ]


with DAG(
    dag_id="hh_vacancies_search",
    start_date=datetime(2026, 3, 1),
    schedule_interval=None,
    catchup=False,
    max_active_runs=1,
    tags=["ingestion", "hh", "vacancies", "search"],
) as dag:

    queries = get_search_queries()

    load_vacancies = PythonOperator.partial(
        task_id="load_vacancies_by_query",
        python_callable=_fetch_and_merge_vacancies_for_query,
        max_active_tis_per_dag=10,
    ).expand(op_kwargs=queries)

    queries >> load_vacancies
