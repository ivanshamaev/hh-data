-- Наполнение хабов из raw.vacancy_details. record_source = 'raw.vacancy_details'.
-- Hash key = md5(business_key). ON CONFLICT DO NOTHING для идемпотентности.

INSERT INTO dv.H_Vacancy (vacancy_hk, vacancy_id, load_dt, record_source)
SELECT md5(d.id), d.id, COALESCE(d.inserted_at, now()), 'raw.vacancy_details'
FROM raw.vacancy_details d
ON CONFLICT (vacancy_hk) DO NOTHING;

INSERT INTO dv.H_Area (area_hk, area_id, load_dt, record_source)
SELECT md5(area_id), area_id, min(inserted_at), 'raw.vacancy_details'
FROM (
    SELECT d.payload->'area'->>'id' AS area_id, d.inserted_at
    FROM raw.vacancy_details d
    WHERE d.payload->'area'->>'id' IS NOT NULL AND (d.payload->'area'->>'id') <> ''
) t
GROUP BY area_id
ON CONFLICT (area_hk) DO NOTHING;

INSERT INTO dv.H_Employer (employer_hk, employer_id, load_dt, record_source)
SELECT md5(employer_id), employer_id, min(inserted_at), 'raw.vacancy_details'
FROM (
    SELECT d.payload->'employer'->>'id' AS employer_id, d.inserted_at
    FROM raw.vacancy_details d
    WHERE d.payload->'employer'->>'id' IS NOT NULL AND (d.payload->'employer'->>'id') <> ''
) t
GROUP BY employer_id
ON CONFLICT (employer_hk) DO NOTHING;

INSERT INTO dv.H_Schedule (schedule_hk, schedule_id, load_dt, record_source)
SELECT md5(schedule_id), schedule_id, min(inserted_at), 'raw.vacancy_details'
FROM (
    SELECT d.payload->'schedule'->>'id' AS schedule_id, d.inserted_at
    FROM raw.vacancy_details d
    WHERE d.payload->'schedule'->>'id' IS NOT NULL AND (d.payload->'schedule'->>'id') <> ''
) t
GROUP BY schedule_id
ON CONFLICT (schedule_hk) DO NOTHING;

INSERT INTO dv.H_Employment (employment_hk, employment_id, load_dt, record_source)
SELECT md5(employment_id), employment_id, min(inserted_at), 'raw.vacancy_details'
FROM (
    SELECT d.payload->'employment'->>'id' AS employment_id, d.inserted_at
    FROM raw.vacancy_details d
    WHERE d.payload->'employment'->>'id' IS NOT NULL AND (d.payload->'employment'->>'id') <> ''
) t
GROUP BY employment_id
ON CONFLICT (employment_hk) DO NOTHING;

INSERT INTO dv.H_Experience (experience_hk, experience_id, load_dt, record_source)
SELECT md5(experience_id), experience_id, min(inserted_at), 'raw.vacancy_details'
FROM (
    SELECT d.payload->'experience'->>'id' AS experience_id, d.inserted_at
    FROM raw.vacancy_details d
    WHERE d.payload->'experience'->>'id' IS NOT NULL AND (d.payload->'experience'->>'id') <> ''
) t
GROUP BY experience_id
ON CONFLICT (experience_hk) DO NOTHING;

INSERT INTO dv.H_BillingType (billing_type_hk, billing_type_id, load_dt, record_source)
SELECT md5(billing_type_id), billing_type_id, min(inserted_at), 'raw.vacancy_details'
FROM (
    SELECT d.payload->'billing_type'->>'id' AS billing_type_id, d.inserted_at
    FROM raw.vacancy_details d
    WHERE d.payload->'billing_type'->>'id' IS NOT NULL AND (d.payload->'billing_type'->>'id') <> ''
) t
GROUP BY billing_type_id
ON CONFLICT (billing_type_hk) DO NOTHING;

INSERT INTO dv.H_EmploymentForm (employment_form_hk, employment_form_id, load_dt, record_source)
SELECT md5(employment_form_id), employment_form_id, min(inserted_at), 'raw.vacancy_details'
FROM (
    SELECT d.payload->'employment_form'->>'id' AS employment_form_id, d.inserted_at
    FROM raw.vacancy_details d
    WHERE d.payload->'employment_form'->>'id' IS NOT NULL AND (d.payload->'employment_form'->>'id') <> ''
) t
GROUP BY employment_form_id
ON CONFLICT (employment_form_hk) DO NOTHING;

-- Профессиональные роли: из массива professional_roles[].id
INSERT INTO dv.H_ProfessionalRole (professional_role_hk, professional_role_id, load_dt, record_source)
SELECT md5(role_id), role_id, min(inserted_at), 'raw.vacancy_details'
FROM (
    SELECT pr.elem->>'id' AS role_id, d.inserted_at
    FROM raw.vacancy_details d,
         jsonb_array_elements(COALESCE(d.payload->'professional_roles', '[]'::jsonb)) AS pr(elem)
    WHERE pr.elem->>'id' IS NOT NULL AND (pr.elem->>'id') <> ''
) t
GROUP BY role_id
ON CONFLICT (professional_role_hk) DO NOTHING;

-- Навыки: key_skills — массив объектов {"name": "..."} или строк
INSERT INTO dv.H_Skill (skill_hk, skill_name, load_dt, record_source)
SELECT md5(skill_name), skill_name, min(inserted_at), 'raw.vacancy_details'
FROM (
    SELECT COALESCE(elem->>'name', elem#>>'{}', elem::text) AS skill_name, d.inserted_at
    FROM raw.vacancy_details d,
         jsonb_array_elements(COALESCE(d.payload->'key_skills', '[]'::jsonb)) AS elem
    WHERE COALESCE(elem->>'name', elem#>>'{}', elem::text) IS NOT NULL
      AND trim(COALESCE(elem->>'name', elem#>>'{}', elem::text)) <> ''
) t
GROUP BY skill_name
ON CONFLICT (skill_hk) DO NOTHING;
