"""
DAG: hh_professional_roles

Загружает данные из API HH.ru professional_roles и раскладывает в raw.categories и raw.roles.
Обработка данных — через Polars.
"""
from __future__ import annotations

import logging
from datetime import datetime

from airflow import DAG
from airflow.decorators import task
from airflow.providers.postgres.hooks.postgres import PostgresHook

DEFAULT_CONN_ID = "pg_conn"
API_URL = "https://api.hh.ru/professional_roles"


def _fetch_and_insert(conn_id: str = DEFAULT_CONN_ID) -> None:
    """Запрашивает API, обрабатывает через Polars и вставляет в raw.categories и raw.roles."""
    import polars as pl
    import requests

    logging.info("Fetching %s", API_URL)
    resp = requests.get(API_URL, timeout=30)
    resp.raise_for_status()
    data = resp.json()
    categories_raw = data.get("categories") or []

    # Категории: одна строка на категорию (Polars)
    df_categories = pl.from_dicts(
        [{"id": str(c["id"]), "name": c["name"]} for c in categories_raw],
        schema={"id": pl.String, "name": pl.String},
    )

    # Роли: разворачиваем вложенные roles в плоскую таблицу (Polars)
    rows_roles = [
        {
            "id": str(r["id"]),
            "category_id": str(c["id"]),
            "name": r["name"],
            "is_default": r.get("is_default", False),
            "search_deprecated": r.get("search_deprecated", False),
            "select_deprecated": r.get("select_deprecated", False),
            "accept_incomplete_resumes": r.get("accept_incomplete_resumes", False),
        }
        for c in categories_raw
        for r in c.get("roles") or []
    ]
    df_roles = (
        pl.from_dicts(rows_roles, schema_overrides={"id": pl.String, "category_id": pl.String})
        if rows_roles
        else pl.DataFrame(schema={
            "id": pl.String, "category_id": pl.String, "name": pl.String,
            "is_default": pl.Boolean, "search_deprecated": pl.Boolean,
            "select_deprecated": pl.Boolean, "accept_incomplete_resumes": pl.Boolean,
        })
    )

    hook = PostgresHook(postgres_conn_id=conn_id)
    conn = hook.get_conn()
    cur = conn.cursor()

    try:
        # Очищаем таблицы перед вставкой (роли зависят от категорий — CASCADE)
        cur.execute("TRUNCATE raw.roles, raw.categories RESTART IDENTITY")
        logging.info("Truncated raw.roles, raw.categories")

        cat_sql = """
            INSERT INTO raw.categories (id, name, inserted_at)
            VALUES (%s, %s, now())
            ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name
        """
        cur.executemany(cat_sql, df_categories.select("id", "name").iter_rows())

        role_sql = """
            INSERT INTO raw.roles (
                id, category_id, name,
                is_default, search_deprecated, select_deprecated, accept_incomplete_resumes,
                inserted_at
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, now())
            ON CONFLICT (id, category_id) DO UPDATE SET
                name = EXCLUDED.name,
                is_default = EXCLUDED.is_default,
                search_deprecated = EXCLUDED.search_deprecated,
                select_deprecated = EXCLUDED.select_deprecated,
                accept_incomplete_resumes = EXCLUDED.accept_incomplete_resumes
        """
        cur.executemany(
            role_sql,
            df_roles.select(
                "id", "category_id", "name",
                "is_default", "search_deprecated", "select_deprecated", "accept_incomplete_resumes",
            ).iter_rows(),
        )
        conn.commit()
    finally:
        cur.close()
        conn.close()

    logging.info(
        "Inserted %d categories and %d roles into raw.categories / raw.roles",
        len(df_categories), len(df_roles),
    )


with DAG(
    dag_id="hh_professional_roles",
    start_date=datetime(2026, 3, 1),
    schedule_interval=None,
    catchup=False,
    max_active_runs=1,
    tags=["ingestion", "hh", "api"],
) as dag:

    @task
    def load_professional_roles():
        _fetch_and_insert(conn_id=DEFAULT_CONN_ID)

    load_professional_roles()
