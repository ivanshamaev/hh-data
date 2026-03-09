-- Наполнение спутников из raw.vacancy_details. record_source = 'raw.vacancy_details'.
-- load_dt = inserted_at по умолчанию. ON CONFLICT DO NOTHING для идемпотентности.

INSERT INTO dv.S_Vacancy_Details (
    vacancy_hk, load_dt, record_source,
    name, type_id, type_name,
    salary_from, salary_to, salary_currency, salary_gross,
    address_raw, address_city, address_street, address_building,
    address_lat, address_lng, address_metro_station_name,
    published_at, created_at, initial_created_at, alternate_url,
    description, description_clean,
    premium, archived, has_test, response_letter_required,
    work_schedule_by_days, work_schedule_by_days_name,
    working_hours, working_hours_name, professional_roles_name,
    updated_at
)
SELECT
    v.vacancy_hk,
    COALESCE(d.inserted_at, now()),
    'raw.vacancy_details',
    d.payload->>'name',
    d.payload->'type'->>'id',
    d.payload->'type'->>'name',
    (d.payload->'salary'->>'from')::numeric,
    (d.payload->'salary'->>'to')::numeric,
    d.payload->'salary'->>'currency',
    (d.payload->'salary'->>'gross')::boolean,
    d.payload->'address'->>'raw',
    d.payload->'address'->>'city',
    d.payload->'address'->>'street',
    d.payload->'address'->>'building',
    (d.payload->'address'->>'lat')::numeric,
    (d.payload->'address'->>'lng')::numeric,
    COALESCE(
        d.payload->'address'->'metro'->>'station_name',
        d.payload->'address'->'metro_stations'->0->>'station_name'
    ),
    (d.payload->>'published_at')::timestamptz,
    (d.payload->>'created_at')::timestamptz,
    (d.payload->>'initial_created_at')::timestamptz,
    d.payload->>'alternate_url',
    d.payload->>'description',
    trim(regexp_replace(regexp_replace(d.payload->>'description', '<[^>]+>', '', 'g'), '\s+', ' ', 'g')),
    (d.payload->>'premium')::boolean,
    (d.payload->>'archived')::boolean,
    (d.payload->>'has_test')::boolean,
    (d.payload->>'response_letter_required')::boolean,
    d.payload->'work_schedule_by_days',
    (SELECT string_agg(elem->>'name', ', ' ORDER BY ord) FROM jsonb_array_elements(COALESCE(d.payload->'work_schedule_by_days', '[]'::jsonb)) WITH ORDINALITY AS t(elem, ord)),
    d.payload->'working_hours',
    (SELECT string_agg(elem->>'name', ', ' ORDER BY ord) FROM jsonb_array_elements(COALESCE(d.payload->'working_hours', '[]'::jsonb)) WITH ORDINALITY AS t(elem, ord)),
    (SELECT string_agg(elem->>'name', ', ' ORDER BY ord) FROM jsonb_array_elements(COALESCE(d.payload->'professional_roles', '[]'::jsonb)) WITH ORDINALITY AS t(elem, ord)),
    now()
FROM raw.vacancy_details d
JOIN dv.H_Vacancy v ON v.vacancy_id = (d.id)::bigint
WHERE d.id ~ '^\d+$'
ON CONFLICT (vacancy_hk, load_dt) DO NOTHING;

-- Спутники справочных хабов (по одной записи на комбинацию hub+атрибуты за загрузку; дубли по разным вакансиям отсекаем по PK)
INSERT INTO dv.S_Area_Details (area_hk, load_dt, record_source, area_name, area_url)
SELECT a.area_hk, COALESCE(d.inserted_at, now()), 'raw.vacancy_details',
       d.payload->'area'->>'name', d.payload->'area'->>'url'
FROM raw.vacancy_details d
JOIN dv.H_Area a ON a.area_id = (d.payload->'area'->>'id')::int
WHERE d.payload->'area'->>'id' IS NOT NULL AND (d.payload->'area'->>'id') <> ''
  AND (d.payload->'area'->>'id') ~ '^\d+$'
ON CONFLICT (area_hk, load_dt) DO NOTHING;

INSERT INTO dv.S_Employer_Details (employer_hk, load_dt, record_source, employer_name, employer_url, employer_logo_240)
SELECT e.employer_hk, COALESCE(d.inserted_at, now()), 'raw.vacancy_details',
       d.payload->'employer'->>'name', d.payload->'employer'->>'url',
       d.payload->'employer'->'logo_urls'->>'240'
FROM raw.vacancy_details d
JOIN dv.H_Employer e ON e.employer_id = (d.payload->'employer'->>'id')::bigint
WHERE d.payload->'employer'->>'id' IS NOT NULL AND (d.payload->'employer'->>'id') <> ''
  AND (d.payload->'employer'->>'id') ~ '^\d+$'
ON CONFLICT (employer_hk, load_dt) DO NOTHING;

INSERT INTO dv.S_Schedule_Details (schedule_hk, load_dt, record_source, schedule_name)
SELECT s.schedule_hk, COALESCE(d.inserted_at, now()), 'raw.vacancy_details',
       d.payload->'schedule'->>'name'
FROM raw.vacancy_details d
JOIN dv.H_Schedule s ON s.schedule_id = d.payload->'schedule'->>'id'
WHERE d.payload->'schedule'->>'id' IS NOT NULL AND (d.payload->'schedule'->>'id') <> ''
ON CONFLICT (schedule_hk, load_dt) DO NOTHING;

INSERT INTO dv.S_Employment_Details (employment_hk, load_dt, record_source, employment_name)
SELECT e.employment_hk, COALESCE(d.inserted_at, now()), 'raw.vacancy_details',
       d.payload->'employment'->>'name'
FROM raw.vacancy_details d
JOIN dv.H_Employment e ON e.employment_id = d.payload->'employment'->>'id'
WHERE d.payload->'employment'->>'id' IS NOT NULL AND (d.payload->'employment'->>'id') <> ''
ON CONFLICT (employment_hk, load_dt) DO NOTHING;

INSERT INTO dv.S_Experience_Details (experience_hk, load_dt, record_source, experience_name)
SELECT e.experience_hk, COALESCE(d.inserted_at, now()), 'raw.vacancy_details',
       d.payload->'experience'->>'name'
FROM raw.vacancy_details d
JOIN dv.H_Experience e ON e.experience_id = d.payload->'experience'->>'id'
WHERE d.payload->'experience'->>'id' IS NOT NULL AND (d.payload->'experience'->>'id') <> ''
ON CONFLICT (experience_hk, load_dt) DO NOTHING;

INSERT INTO dv.S_BillingType_Details (billing_type_hk, load_dt, record_source, billing_type_name)
SELECT b.billing_type_hk, COALESCE(d.inserted_at, now()), 'raw.vacancy_details',
       d.payload->'billing_type'->>'name'
FROM raw.vacancy_details d
JOIN dv.H_BillingType b ON b.billing_type_id = d.payload->'billing_type'->>'id'
WHERE d.payload->'billing_type'->>'id' IS NOT NULL AND (d.payload->'billing_type'->>'id') <> ''
ON CONFLICT (billing_type_hk, load_dt) DO NOTHING;

INSERT INTO dv.S_EmploymentForm_Details (employment_form_hk, load_dt, record_source, employment_form_name)
SELECT f.employment_form_hk, COALESCE(d.inserted_at, now()), 'raw.vacancy_details',
       d.payload->'employment_form'->>'name'
FROM raw.vacancy_details d
JOIN dv.H_EmploymentForm f ON f.employment_form_id = d.payload->'employment_form'->>'id'
WHERE d.payload->'employment_form'->>'id' IS NOT NULL AND (d.payload->'employment_form'->>'id') <> ''
ON CONFLICT (employment_form_hk, load_dt) DO NOTHING;

-- Профессиональные роли: одна запись спутника на (роль, load_dt) из каждой вакансии с этой ролью
INSERT INTO dv.S_ProfessionalRole_Details (professional_role_hk, load_dt, record_source, professional_role_name)
SELECT r.professional_role_hk, COALESCE(d.inserted_at, now()), 'raw.vacancy_details', pr.elem->>'name'
FROM raw.vacancy_details d
CROSS JOIN LATERAL jsonb_array_elements(COALESCE(d.payload->'professional_roles', '[]'::jsonb)) AS pr(elem)
JOIN dv.H_ProfessionalRole r ON r.professional_role_id = (pr.elem->>'id')::int
WHERE pr.elem->>'id' IS NOT NULL AND (pr.elem->>'id') <> ''
  AND (pr.elem->>'id') ~ '^\d+$'
ON CONFLICT (professional_role_hk, load_dt) DO NOTHING;
