"""
DAG: init_db

Запускает все SQL-файлы из папки ddl в цикле через mapped tasks.
Подключение к PostgreSQL: pg_conn (PostgresHook).
"""
from __future__ import annotations

import logging
from datetime import datetime
from pathlib import Path

from airflow import DAG
from airflow.decorators import task
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook

DEFAULT_CONN_ID = "pg_conn"

# Директория с DDL относительно файла DAG
THIS_DIR = Path(__file__).resolve().parent
DDL_DIR = THIS_DIR / "ddl"


def _run_ddl_sql(ddl_file: str, **kwargs) -> None:
    """Читает SQL из файла и выполняет его в PostgreSQL."""
    conn_id = kwargs.get("conn_id", DEFAULT_CONN_ID)
    ddl_path = DDL_DIR / ddl_file
    if not ddl_path.exists():
        raise FileNotFoundError(f"DDL file not found: {ddl_path}")

    sql = ddl_path.read_text()
    logging.info("Running DDL: %s (%s)", ddl_file, ddl_path)

    hook = PostgresHook(postgres_conn_id=conn_id)
    # run() выполняет один или несколько операторов через cursor.execute
    hook.run(sql)
    logging.info("DDL completed: %s", ddl_file)


@task
def get_ddl_files() -> list[dict[str, str]]:
    """Возвращает список словарей с именами DDL-файлов для .expand()."""
    if not DDL_DIR.exists():
        logging.warning("DDL dir does not exist: %s", DDL_DIR)
        return []

    files = sorted(f.name for f in DDL_DIR.glob("*.sql"))
    result = [
        {"ddl_file": f, "conn_id": DEFAULT_CONN_ID}
        for f in files
    ]
    logging.info("DDL files to run: %s", files)
    return result


with DAG(
    dag_id="init_db",
    start_date=datetime(2026, 3, 1),
    schedule_interval=None,
    catchup=False,
    max_active_runs=1,
    tags=["init", "ddl"],
) as dag:

    ddl_list = get_ddl_files()

    run_ddl = PythonOperator.partial(
        task_id="run_ddl",
        python_callable=_run_ddl_sql,
    ).expand(op_kwargs=ddl_list)

    ddl_list >> run_ddl
