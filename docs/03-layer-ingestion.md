# 03 — Слой загрузки (Ingestion)

Здесь описывается, **где** и **как** выполняются выгрузки из API HH.ru в слой `raw`: какие DAG'и, какие таблицы заполняют, в каком порядке их имеет смысл запускать.

## Назначение

- Получить данные из API и записать их в таблицы схемы `raw` (JSON в `payload` и/или распарсенные поля).
- Обеспечить дельту по деталям вакансий (загружать только те id, которых ещё нет в `vacancy_details_loaded`).
- Постобработка: разбор JSON деталей в широкую таблицу `raw.vacancy_details_wide`.

## Порядок загрузки (логический)

1. Справочник профессиональных ролей (один раз или редко).
2. Вакансии: по Москве по ролям, по СПб, по поисковым запросам (как нужно).
3. Детали вакансий по id из выбранного набора (например, из `raw.vacancies_for_details`), с дельтой по `vacancy_details_loaded`.
4. Постобработка: обновление `raw.vacancy_details_wide` из `raw.vacancy_details`.

## DAG'и загрузки

Расположение: `airflow/dags/ingestion/`.

| DAG | Назначение | Куда пишет |
|-----|------------|------------|
| **hh_professional_roles** | Загрузка справочника профессиональных ролей (API) | `raw.categories`, `raw.roles` |
| **hh_vacancies_moscow** | Вакансии по Москве для каждой роли из `raw.roles` | `raw.vacancies` |
| **hh_vacancies_spb** | Вакансии по Санкт-Петербургу по ролям | `raw.vacancies` (другой регион в логике запроса) |
| **hh_vacancies_search** | Вакансии по поисковым фразам (параметр `text`) | `raw.vacancies_search` |
| **hh_vacancy_details** | Детали вакансий GET /vacancies/{id}; дельта по `vacancy_details_loaded`; источник id — например `raw.vacancies_for_details` | `raw.vacancy_details`, `raw.vacancy_details_loaded` |
| **vacancy_details_wide** | Постобработка: разбор `raw.vacancy_details.payload` в колонки | `raw.vacancy_details_wide` (INSERT/UPDATE по id) |

## Где что делается

- **Роли**: DAG читает API справочника ролей, заполняет `raw.categories` и `raw.roles`.
- **Вакансии (Москва/СПб/поиск)**: запросы к API /vacancies с нужными параметрами (area, professional_role, text); полный JSON в `payload`, плюс извлечённые поля для удобства (name, salary_*, employer_id и т.д.).
- **Детали вакансий**: DAG выбирает id из view/таблицы (например, `raw.vacancies_for_details` минус уже загруженные в `vacancy_details_loaded`), для каждого id вызывает GET /vacancies/{id}, пишет ответ в `raw.vacancy_details` и id в `raw.vacancy_details_loaded`. Ограничения по rate limit и длительности работы заданы в коде DAG.
- **Wide**: один SQL-скрипт (`ingestion/sql/refresh_vacancy_details_wide.sql`) читает `raw.vacancy_details`, разбирает `payload` (jsonb) в колонки и пишет в `raw.vacancy_details_wide` (ON CONFLICT DO UPDATE).

После выполнения этих шагов слой `raw` готов для аналитики по wide-таблице и для трансформации в Data Vault (раздел 05).
