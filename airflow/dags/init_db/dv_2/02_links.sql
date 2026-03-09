-- Raw DV 2.0: линки (связи многие-к-одному и многие-ко-многим между хабами).
-- Link key = UUID от MD5(concat parent hub keys), load_dt, record_source.

-- Вакансия — Регион (N:1)
CREATE TABLE IF NOT EXISTS dv.L_Vacancy_Area (
    vacancy_area_hk   UUID NOT NULL PRIMARY KEY,
    vacancy_hk        UUID NOT NULL REFERENCES dv.H_Vacancy(vacancy_hk),
    area_hk           UUID NOT NULL REFERENCES dv.H_Area(area_hk),
    load_dt           TIMESTAMPTZ NOT NULL DEFAULT now(),
    record_source     TEXT NOT NULL DEFAULT 'raw.vacancy_details_wide'
);
COMMENT ON TABLE dv.L_Vacancy_Area IS 'Link: вакансия — регион (N:1)';

-- Вакансия — Работодатель (N:1)
CREATE TABLE IF NOT EXISTS dv.L_Vacancy_Employer (
    vacancy_employer_hk   UUID NOT NULL PRIMARY KEY,
    vacancy_hk            UUID NOT NULL REFERENCES dv.H_Vacancy(vacancy_hk),
    employer_hk           UUID NOT NULL REFERENCES dv.H_Employer(employer_hk),
    load_dt               TIMESTAMPTZ NOT NULL DEFAULT now(),
    record_source         TEXT NOT NULL DEFAULT 'raw.vacancy_details_wide'
);
COMMENT ON TABLE dv.L_Vacancy_Employer IS 'Link: вакансия — работодатель (N:1)';

-- Вакансия — График (N:1)
CREATE TABLE IF NOT EXISTS dv.L_Vacancy_Schedule (
    vacancy_schedule_hk   UUID NOT NULL PRIMARY KEY,
    vacancy_hk            UUID NOT NULL REFERENCES dv.H_Vacancy(vacancy_hk),
    schedule_hk           UUID NOT NULL REFERENCES dv.H_Schedule(schedule_hk),
    load_dt               TIMESTAMPTZ NOT NULL DEFAULT now(),
    record_source         TEXT NOT NULL DEFAULT 'raw.vacancy_details_wide'
);
COMMENT ON TABLE dv.L_Vacancy_Schedule IS 'Link: вакансия — график работы (N:1)';

-- Вакансия — Тип занятости (N:1)
CREATE TABLE IF NOT EXISTS dv.L_Vacancy_Employment (
    vacancy_employment_hk   UUID NOT NULL PRIMARY KEY,
    vacancy_hk              UUID NOT NULL REFERENCES dv.H_Vacancy(vacancy_hk),
    employment_hk           UUID NOT NULL REFERENCES dv.H_Employment(employment_hk),
    load_dt                 TIMESTAMPTZ NOT NULL DEFAULT now(),
    record_source           TEXT NOT NULL DEFAULT 'raw.vacancy_details_wide'
);
COMMENT ON TABLE dv.L_Vacancy_Employment IS 'Link: вакансия — тип занятости (N:1)';

-- Вакансия — Опыт (N:1)
CREATE TABLE IF NOT EXISTS dv.L_Vacancy_Experience (
    vacancy_experience_hk   UUID NOT NULL PRIMARY KEY,
    vacancy_hk              UUID NOT NULL REFERENCES dv.H_Vacancy(vacancy_hk),
    experience_hk           UUID NOT NULL REFERENCES dv.H_Experience(experience_hk),
    load_dt                 TIMESTAMPTZ NOT NULL DEFAULT now(),
    record_source           TEXT NOT NULL DEFAULT 'raw.vacancy_details_wide'
);
COMMENT ON TABLE dv.L_Vacancy_Experience IS 'Link: вакансия — требуемый опыт (N:1)';

-- Вакансия — Тип биллинга (N:1)
CREATE TABLE IF NOT EXISTS dv.L_Vacancy_BillingType (
    vacancy_billing_type_hk   UUID NOT NULL PRIMARY KEY,
    vacancy_hk                UUID NOT NULL REFERENCES dv.H_Vacancy(vacancy_hk),
    billing_type_hk           UUID NOT NULL REFERENCES dv.H_BillingType(billing_type_hk),
    load_dt                   TIMESTAMPTZ NOT NULL DEFAULT now(),
    record_source             TEXT NOT NULL DEFAULT 'raw.vacancy_details_wide'
);
COMMENT ON TABLE dv.L_Vacancy_BillingType IS 'Link: вакансия — тип биллинга (N:1)';

-- Вакансия — Форма занятости (N:1)
CREATE TABLE IF NOT EXISTS dv.L_Vacancy_EmploymentForm (
    vacancy_employment_form_hk   UUID NOT NULL PRIMARY KEY,
    vacancy_hk                   UUID NOT NULL REFERENCES dv.H_Vacancy(vacancy_hk),
    employment_form_hk           UUID NOT NULL REFERENCES dv.H_EmploymentForm(employment_form_hk),
    load_dt                      TIMESTAMPTZ NOT NULL DEFAULT now(),
    record_source                TEXT NOT NULL DEFAULT 'raw.vacancy_details_wide'
);
COMMENT ON TABLE dv.L_Vacancy_EmploymentForm IS 'Link: вакансия — форма занятости (N:1)';

-- Вакансия — Профессиональная роль (M:N)
CREATE TABLE IF NOT EXISTS dv.L_Vacancy_ProfessionalRole (
    vacancy_professional_role_hk   UUID NOT NULL PRIMARY KEY,
    vacancy_hk                     UUID NOT NULL REFERENCES dv.H_Vacancy(vacancy_hk),
    professional_role_hk           UUID NOT NULL REFERENCES dv.H_ProfessionalRole(professional_role_hk),
    load_dt                        TIMESTAMPTZ NOT NULL DEFAULT now(),
    record_source                  TEXT NOT NULL DEFAULT 'raw.vacancy_details_wide'
);
COMMENT ON TABLE dv.L_Vacancy_ProfessionalRole IS 'Link: вакансия — профессиональная роль (M:N)';

-- Вакансия — Навык (M:N)
CREATE TABLE IF NOT EXISTS dv.L_Vacancy_Skill (
    vacancy_skill_hk   UUID NOT NULL PRIMARY KEY,
    vacancy_hk         UUID NOT NULL REFERENCES dv.H_Vacancy(vacancy_hk),
    skill_hk           UUID NOT NULL REFERENCES dv.H_Skill(skill_hk),
    load_dt            TIMESTAMPTZ NOT NULL DEFAULT now(),
    record_source      TEXT NOT NULL DEFAULT 'raw.vacancy_details_wide'
);
COMMENT ON TABLE dv.L_Vacancy_Skill IS 'Link: вакансия — навык (M:N)';
