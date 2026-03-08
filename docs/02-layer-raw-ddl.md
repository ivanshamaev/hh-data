# 02 — Слой Raw: DDL

Здесь описывается, **где** и **как** создаётся слой сырых данных: схема, таблицы, представления. Всё это делается DAG'ами инициализации БД, без загрузки данных из API.

## Назначение слоя Raw

- Хранить ответы API «как есть» (JSON в колонке `payload` или отдельные таблицы под справочники).
- Минимум преобразований: только структура таблиц и, при необходимости, представления для отбора подмножества данных (например, вакансии по выбранным ролям для загрузки деталей).

## Где лежит DDL

- **Схема `raw` и таблицы raw**: `airflow/dags/init_db/ddl/` — SQL-файлы в алфавитном порядке.
- **Схема `dv` и объекты Data Vault**: `airflow/dags/init_db/dv_2/` — отдельно (см. раздел 04).

## DAG init_db

- **Файл**: `airflow/dags/init_db/dag_init_db.py`
- **Действие**: выполняет все `*.sql` из `init_db/ddl/` в порядке по имени файла.
- **Подключение**: `pg_conn` (PostgresHook).

Порядок выполнения DDL (по именам файлов в `ddl/`):

| Файл | Что создаётся |
|------|----------------|
| `02_raw_hh_professional_roles.sql` | Схема `raw`, таблицы `raw.categories`, `raw.roles` (справочник профессиональных ролей из API) |
| `03_raw_vacancies.sql` | `raw.vacancies` — вакансии по Москве по ролям (payload + распарсенные поля) |
| `04_raw_vacancies_search.sql` | `raw.vacancies_search` — вакансии по поисковым запросам (payload + поля) |
| `05_raw_vacancy_details.sql` | `raw.vacancy_details` (id, payload, inserted_at), `raw.vacancy_details_loaded`, `raw.vacancy_details_batch` |
| `06_raw_view_vacancies_for_details.sql` | Представление `raw.vacancies_for_details` — вакансии по выбранным ролям для загрузки деталей |
| `07_raw_vacancy_details_wide.sql` | `raw.vacancy_details_wide` — широкий разбор полей из `vacancy_details.payload` |

## Объекты схемы raw (кратко)

- **categories, roles** — справочник профессиональных ролей HH.ru (заполняется отдельным DAG из API).
- **vacancies** — вакансии Москвы по ролям; **vacancies_search** — вакансии по поисковым фразам.
- **vacancy_details** — полный JSON деталей вакансии (GET /vacancies/{id}); **vacancy_details_loaded** — учёт уже загруженных id (дельта); **vacancy_details_batch** — служебная разбивка по батчам.
- **vacancies_for_details** — view поверх `vacancies` + `roles`: только роли типа «программист», «разработчик», «аналитик» и т.д., откуда берутся id для загрузки деталей.
- **vacancy_details_wide** — одна строка на вакансию, колонки — разобранные поля из payload (название, зарплата, адрес, работодатель, график, навыки, роли и т.д.); обновляется постобработкой из `raw.vacancy_details`.

Инициализация только создаёт структуру; наполнение таблиц выполняется DAG'ами загрузки (см. раздел 03).
