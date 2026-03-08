"""
DAG: init_dv2

Запускает DDL Raw Data Vault 2.0 в порядке: схема → хабы → линки → спутники.
Подключение к PostgreSQL: pg_conn (PostgresHook).
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
DV2_DDL_DIR = THIS_DIR / "dv_2"


def _run_ddl_sql(ddl_file: str, **kwargs) -> None:
    """Читает SQL из файла и выполняет его в PostgreSQL."""
    conn_id = kwargs.get("conn_id", DEFAULT_CONN_ID)
    ddl_path = DV2_DDL_DIR / ddl_file
    if not ddl_path.exists():
        raise FileNotFoundError(f"DDL file not found: {ddl_path}")

    sql = ddl_path.read_text()
    logging.info("Running DDL: %s (%s)", ddl_file, ddl_path)

    hook = PostgresHook(postgres_conn_id=conn_id)
    hook.run(sql)
    logging.info("DDL completed: %s", ddl_file)


# Порядок выполнения DDL: схема → хабы → линки → спутники
DDL_ORDER = ("00_schema.sql", "01_hubs.sql", "02_links.sql", "03_satellites.sql")


with DAG(
    dag_id="init_dv2",
    start_date=datetime(2026, 3, 1),
    schedule_interval=None,
    catchup=False,
    max_active_runs=1,
    tags=["init", "ddl", "dv2"],
) as dag:

    tasks = []
    for ddl_file in DDL_ORDER:
        task_id = f"run_{ddl_file.removesuffix('.sql')}"
        t = PythonOperator(
            task_id=task_id,
            python_callable=_run_ddl_sql,
            op_kwargs={"ddl_file": ddl_file, "conn_id": DEFAULT_CONN_ID},
        )
        tasks.append(t)

    for i in range(len(tasks) - 1):
        tasks[i] >> tasks[i + 1]
