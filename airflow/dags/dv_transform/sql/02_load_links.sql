-- Наполнение линков из raw.vacancy_details. record_source = 'raw.vacancy_details'.
-- Link key = md5(vacancy_hk || '|' || other_hk). ON CONFLICT DO NOTHING.

INSERT INTO dv.L_Vacancy_Area (vacancy_area_hk, vacancy_hk, area_hk, load_dt, record_source)
SELECT md5(v.vacancy_hk || '|' || a.area_hk), v.vacancy_hk, a.area_hk, d.inserted_at, 'raw.vacancy_details'
FROM raw.vacancy_details d
JOIN dv.H_Vacancy v ON v.vacancy_id = d.id
JOIN dv.H_Area a ON a.area_id = d.payload->'area'->>'id'
WHERE d.payload->'area'->>'id' IS NOT NULL AND (d.payload->'area'->>'id') <> ''
ON CONFLICT (vacancy_area_hk) DO NOTHING;

INSERT INTO dv.L_Vacancy_Employer (vacancy_employer_hk, vacancy_hk, employer_hk, load_dt, record_source)
SELECT md5(v.vacancy_hk || '|' || e.employer_hk), v.vacancy_hk, e.employer_hk, d.inserted_at, 'raw.vacancy_details'
FROM raw.vacancy_details d
JOIN dv.H_Vacancy v ON v.vacancy_id = d.id
JOIN dv.H_Employer e ON e.employer_id = d.payload->'employer'->>'id'
WHERE d.payload->'employer'->>'id' IS NOT NULL AND (d.payload->'employer'->>'id') <> ''
ON CONFLICT (vacancy_employer_hk) DO NOTHING;

INSERT INTO dv.L_Vacancy_Schedule (vacancy_schedule_hk, vacancy_hk, schedule_hk, load_dt, record_source)
SELECT md5(v.vacancy_hk || '|' || s.schedule_hk), v.vacancy_hk, s.schedule_hk, d.inserted_at, 'raw.vacancy_details'
FROM raw.vacancy_details d
JOIN dv.H_Vacancy v ON v.vacancy_id = d.id
JOIN dv.H_Schedule s ON s.schedule_id = d.payload->'schedule'->>'id'
WHERE d.payload->'schedule'->>'id' IS NOT NULL AND (d.payload->'schedule'->>'id') <> ''
ON CONFLICT (vacancy_schedule_hk) DO NOTHING;

INSERT INTO dv.L_Vacancy_Employment (vacancy_employment_hk, vacancy_hk, employment_hk, load_dt, record_source)
SELECT md5(v.vacancy_hk || '|' || e.employment_hk), v.vacancy_hk, e.employment_hk, d.inserted_at, 'raw.vacancy_details'
FROM raw.vacancy_details d
JOIN dv.H_Vacancy v ON v.vacancy_id = d.id
JOIN dv.H_Employment e ON e.employment_id = d.payload->'employment'->>'id'
WHERE d.payload->'employment'->>'id' IS NOT NULL AND (d.payload->'employment'->>'id') <> ''
ON CONFLICT (vacancy_employment_hk) DO NOTHING;

INSERT INTO dv.L_Vacancy_Experience (vacancy_experience_hk, vacancy_hk, experience_hk, load_dt, record_source)
SELECT md5(v.vacancy_hk || '|' || e.experience_hk), v.vacancy_hk, e.experience_hk, d.inserted_at, 'raw.vacancy_details'
FROM raw.vacancy_details d
JOIN dv.H_Vacancy v ON v.vacancy_id = d.id
JOIN dv.H_Experience e ON e.experience_id = d.payload->'experience'->>'id'
WHERE d.payload->'experience'->>'id' IS NOT NULL AND (d.payload->'experience'->>'id') <> ''
ON CONFLICT (vacancy_experience_hk) DO NOTHING;

INSERT INTO dv.L_Vacancy_BillingType (vacancy_billing_type_hk, vacancy_hk, billing_type_hk, load_dt, record_source)
SELECT md5(v.vacancy_hk || '|' || b.billing_type_hk), v.vacancy_hk, b.billing_type_hk, d.inserted_at, 'raw.vacancy_details'
FROM raw.vacancy_details d
JOIN dv.H_Vacancy v ON v.vacancy_id = d.id
JOIN dv.H_BillingType b ON b.billing_type_id = d.payload->'billing_type'->>'id'
WHERE d.payload->'billing_type'->>'id' IS NOT NULL AND (d.payload->'billing_type'->>'id') <> ''
ON CONFLICT (vacancy_billing_type_hk) DO NOTHING;

INSERT INTO dv.L_Vacancy_EmploymentForm (vacancy_employment_form_hk, vacancy_hk, employment_form_hk, load_dt, record_source)
SELECT md5(v.vacancy_hk || '|' || f.employment_form_hk), v.vacancy_hk, f.employment_form_hk, d.inserted_at, 'raw.vacancy_details'
FROM raw.vacancy_details d
JOIN dv.H_Vacancy v ON v.vacancy_id = d.id
JOIN dv.H_EmploymentForm f ON f.employment_form_id = d.payload->'employment_form'->>'id'
WHERE d.payload->'employment_form'->>'id' IS NOT NULL AND (d.payload->'employment_form'->>'id') <> ''
ON CONFLICT (vacancy_employment_form_hk) DO NOTHING;

-- Вакансия — Профессиональная роль (M:N)
INSERT INTO dv.L_Vacancy_ProfessionalRole (vacancy_professional_role_hk, vacancy_hk, professional_role_hk, load_dt, record_source)
SELECT md5(v.vacancy_hk || '|' || r.professional_role_hk), v.vacancy_hk, r.professional_role_hk, d.inserted_at, 'raw.vacancy_details'
FROM raw.vacancy_details d
JOIN dv.H_Vacancy v ON v.vacancy_id = d.id
CROSS JOIN LATERAL jsonb_array_elements(COALESCE(d.payload->'professional_roles', '[]'::jsonb)) AS pr(elem)
JOIN dv.H_ProfessionalRole r ON r.professional_role_id = pr.elem->>'id'
WHERE pr.elem->>'id' IS NOT NULL AND (pr.elem->>'id') <> ''
ON CONFLICT (vacancy_professional_role_hk) DO NOTHING;

-- Вакансия — Навык (M:N)
INSERT INTO dv.L_Vacancy_Skill (vacancy_skill_hk, vacancy_hk, skill_hk, load_dt, record_source)
SELECT md5(v.vacancy_hk || '|' || s.skill_hk), v.vacancy_hk, s.skill_hk, d.inserted_at, 'raw.vacancy_details'
FROM raw.vacancy_details d
JOIN dv.H_Vacancy v ON v.vacancy_id = d.id
CROSS JOIN LATERAL jsonb_array_elements(COALESCE(d.payload->'key_skills', '[]'::jsonb)) AS ks(elem)
JOIN dv.H_Skill s ON s.skill_name = trim(COALESCE(ks.elem->>'name', ks.elem#>>'{}', ks.elem::text))
WHERE trim(COALESCE(ks.elem->>'name', ks.elem#>>'{}', ks.elem::text)) <> ''
ON CONFLICT (vacancy_skill_hk) DO NOTHING;
