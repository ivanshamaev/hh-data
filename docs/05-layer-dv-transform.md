# 05 — Трансформация в DV

Здесь описывается, **где** и **как** наполняются объекты Data Vault 2.0 (хабы, линки, спутники) из сырых данных. Источник — таблица `raw.vacancy_details` (полный JSON в `payload`).

## Назначение

- Прочитать все записи из `raw.vacancy_details`, разобрать `payload` (JSONB) и вставить данные в схему `dv` в порядке: сначала хабы, затем линки, затем спутники.
- Обеспечить идемпотентность: повторный запуск не создаёт дубликатов (ON CONFLICT DO NOTHING для хабов и линков, для спутников — по (parent_hk, load_dt)).

## Где что делается

- **DAG**: `airflow/dags/dv_transform/dag_dv_transform.py` — DAG **dv_transform**.
- **SQL**: в папке `airflow/dags/dv_transform/sql/`, выполняются по порядку:
  - `01_load_hubs.sql`
  - `02_load_links.sql`
  - `03_load_satellites.sql`

Подключение к БД: `pg_conn` (PostgresHook).

## 01_load_hubs.sql

- Читает `raw.vacancy_details`, извлекает бизнес-ключи из `payload`.
- Вставляет в каждый хаб с `record_source = 'raw.vacancy_details'`, hash key = MD5(business_key).
- **H_Vacancy**: по полю `id` (одна запись на вакансию).
- **H_Area, H_Employer, H_Schedule, H_Employment, H_Experience, H_BillingType, H_EmploymentForm**: по полям `payload->'area'->>'id'`, `payload->'employer'->>'id'` и т.д.; используются только непустые значения, группировка по ключу и min(inserted_at) для load_dt.
- **H_ProfessionalRole**: разворот массива `payload->'professional_roles'`, бизнес-ключ — `id` элемента.
- **H_Skill**: разворот массива `payload->'key_skills'` (поддержка и объекта с полем `name`, и строки), бизнес-ключ — название навыка.

Все вставки с ON CONFLICT DO NOTHING, чтобы при повторном запуске не падать и не дублировать ключи.

## 02_load_links.sql

- Для каждой записи в `raw.vacancy_details` вычисляются hash-ключи хабов (vacancy_hk, area_hk и т.д.) через JOIN с уже заполненными хабами.
- Вставляются строки в линки: ключ линка = MD5(vacancy_hk || '|' || other_hk). Связи M:N (вакансия–роль, вакансия–навык) строятся через разворот массивов `professional_roles` и `key_skills` с JOIN к соответствующим хабам.
- record_source = 'raw.vacancy_details', load_dt = inserted_at строки источника. ON CONFLICT DO NOTHING.

## 03_load_satellites.sql

- **S_Vacancy_Details**: одна строка на вакансию; атрибуты извлекаются из `payload` (название, зарплата, адрес, даты, описание, флаги, график по дням/часам, professional_roles_name как string_agg и т.д.). PK (vacancy_hk, load_dt), load_dt = inserted_at.
- Спутники справочных хабов (S_Area_Details, S_Employer_Details, S_Schedule_Details и т.д.): вставка по одной записи на комбинацию (hub, момент загрузки из строки vacancy_details); атрибуты (name, url и т.д.) берутся из того же payload. ON CONFLICT (parent_hk, load_dt) DO NOTHING.

В результате слой `dv` отражает содержимое `raw.vacancy_details` в нормализованном виде с возможностью истории по load_dt. Запуск DAG можно повторять после каждой новой загрузки деталей в raw.
