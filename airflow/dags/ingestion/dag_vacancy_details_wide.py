"""
DAG: vacancy_details_wide

Постобработка raw.vacancy_details: разбор JSON (payload) в широкую таблицу raw.vacancy_details_wide.
Всё выполняется в PostgreSQL (скрипт sql/refresh_vacancy_details_wide.sql).
"""
from __future__ import annotations

import logging
from pathlib import Path
from datetime import datetime

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook

DEFAULT_CONN_ID = "pg_conn"
THIS_DIR = Path(__file__).resolve().parent
REFRESH_SQL_PATH = THIS_DIR / "sql" / "refresh_vacancy_details_wide.sql"


def _refresh_vacancy_details_wide(conn_id: str = DEFAULT_CONN_ID) -> None:
    """Выполняет SQL постобработки: raw.vacancy_details -> raw.vacancy_details_wide."""
    if not REFRESH_SQL_PATH.exists():
        raise FileNotFoundError(f"SQL script not found: {REFRESH_SQL_PATH}")
    sql = REFRESH_SQL_PATH.read_text()
    hook = PostgresHook(postgres_conn_id=conn_id)
    logging.info("Running refresh_vacancy_details_wide.sql")
    hook.run(sql)
    logging.info("Refresh completed: raw.vacancy_details_wide updated from raw.vacancy_details")


with DAG(
    dag_id="vacancy_details_wide",
    start_date=datetime(2026, 3, 1),
    schedule_interval=None,
    catchup=False,
    tags=["ingestion", "hh", "postprocess"],
) as dag:

    PythonOperator(
        task_id="refresh_wide",
        python_callable=_refresh_vacancy_details_wide,
        op_kwargs={"conn_id": DEFAULT_CONN_ID},
    )
