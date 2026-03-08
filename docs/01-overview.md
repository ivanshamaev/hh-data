# 01 — Обзор и стек

## Цель проекта

- Собирать данные о вакансиях HH.ru через публичное API.
- Хранить сырые ответы (raw), строить широкую таблицу для аналитики и слой Raw Data Vault 2.0 для нормализованного хранилища с историей и связями.

## Стек

- **Оркестрация**: Apache Airflow (DAG'и загрузки и трансформации).
- **Хранилище**: PostgreSQL (схемы `raw` и `dv`).
- **Источник**: API HH.ru (вакансии, детали вакансий, справочник профессиональных ролей).

## Общий поток данных

```
API HH.ru
    │
    ├─► professional_roles  ──► raw.categories, raw.roles
    ├─► /vacancies (Москва) ──► raw.vacancies
    ├─► /vacancies (поиск)  ──► raw.vacancies_search
    └─► /vacancies/{id}     ──► raw.vacancy_details
                                    │
                                    ├─► raw.vacancy_details_wide (постобработка)
                                    └─► dv.* (хабы, линки, спутники)
```

Сначала выполняется инициализация БД (DDL), затем периодическая или ручная загрузка (ingestion), затем трансформация в Data Vault (dv_transform).

## Структура репозитория (основное)

- `airflow/dags/init_db/` — DAG и DDL для создания схемы `raw` и таблиц; отдельно `dv_2/` и DAG `init_dv2` для схемы `dv`.
- `airflow/dags/ingestion/` — DAG'и выгрузки из API и постобработки (wide).
- `airflow/dags/dv_transform/` — DAG и SQL наполнения Data Vault из `raw.vacancy_details`.
- `docs/` — эта документация и диаграмма слоёв.

Подробное описание по слоям — в следующих разделах.
