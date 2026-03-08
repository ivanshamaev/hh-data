"""
DAG: dv_transform

Наполнение Raw Data Vault 2.0 (схема dv) из raw.vacancy_details.
Порядок: хабы → линки → спутники. Подключение: pg_conn (PostgresHook).
"""
from __future__ import annotations

import logging
from datetime import datetime
from pathlib import Path

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook

DEFAULT_CONN_ID = "pg_conn"
THIS_DIR = Path(__file__).resolve().parent
SQL_DIR = THIS_DIR / "sql"

LOAD_ORDER = ("01_load_hubs.sql", "02_load_links.sql", "03_load_satellites.sql")


def _run_sql(ddl_file: str, **kwargs) -> None:
    """Читает SQL из файла и выполняет в PostgreSQL."""
    conn_id = kwargs.get("conn_id", DEFAULT_CONN_ID)
    path = SQL_DIR / ddl_file
    if not path.exists():
        raise FileNotFoundError(f"SQL file not found: {path}")
    sql = path.read_text()
    logging.info("Running: %s", ddl_file)
    hook = PostgresHook(postgres_conn_id=conn_id)
    hook.run(sql)
    logging.info("Completed: %s", ddl_file)


with DAG(
    dag_id="dv_transform",
    start_date=datetime(2026, 3, 1),
    schedule_interval=None,
    catchup=False,
    tags=["dv", "transform", "vacancy_details"],
) as dag:

    tasks = []
    for sql_file in LOAD_ORDER:
        t = PythonOperator(
            task_id=sql_file.removesuffix(".sql"),
            python_callable=_run_sql,
            op_kwargs={"ddl_file": sql_file, "conn_id": DEFAULT_CONN_ID},
        )
        tasks.append(t)

    for i in range(len(tasks) - 1):
        tasks[i] >> tasks[i + 1]
