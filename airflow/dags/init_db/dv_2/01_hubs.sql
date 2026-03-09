-- Raw DV 2.0: хабы (бизнес-ключи сущностей). HK = UUID от MD5(business_key), record_source, load_dt.

-- Вакансия (id в API — числовой, может быть большим)
CREATE TABLE IF NOT EXISTS dv.H_Vacancy (
    vacancy_hk     UUID NOT NULL PRIMARY KEY,
    vacancy_id     BIGINT NOT NULL UNIQUE,
    load_dt        TIMESTAMPTZ NOT NULL DEFAULT now(),
    record_source  TEXT NOT NULL DEFAULT 'raw.vacancy_details_wide'
);
COMMENT ON TABLE dv.H_Vacancy IS 'Hub: вакансия (business key: id)';

-- Регион/город (area.id в API — целое число)
CREATE TABLE IF NOT EXISTS dv.H_Area (
    area_hk        UUID NOT NULL PRIMARY KEY,
    area_id        INT NOT NULL UNIQUE,
    load_dt        TIMESTAMPTZ NOT NULL DEFAULT now(),
    record_source  TEXT NOT NULL DEFAULT 'raw.vacancy_details_wide'
);
COMMENT ON TABLE dv.H_Area IS 'Hub: регион/город (business key: area.id)';

-- Работодатель (employer.id в API — числовой)
CREATE TABLE IF NOT EXISTS dv.H_Employer (
    employer_hk    UUID NOT NULL PRIMARY KEY,
    employer_id    BIGINT NOT NULL UNIQUE,
    load_dt        TIMESTAMPTZ NOT NULL DEFAULT now(),
    record_source  TEXT NOT NULL DEFAULT 'raw.vacancy_details_wide'
);
COMMENT ON TABLE dv.H_Employer IS 'Hub: работодатель (business key: employer.id)';

-- График работы (schedule)
CREATE TABLE IF NOT EXISTS dv.H_Schedule (
    schedule_hk    UUID NOT NULL PRIMARY KEY,
    schedule_id    TEXT NOT NULL UNIQUE,
    load_dt        TIMESTAMPTZ NOT NULL DEFAULT now(),
    record_source  TEXT NOT NULL DEFAULT 'raw.vacancy_details_wide'
);
COMMENT ON TABLE dv.H_Schedule IS 'Hub: график работы (business key: schedule.id)';

-- Тип занятости (employment)
CREATE TABLE IF NOT EXISTS dv.H_Employment (
    employment_hk     UUID NOT NULL PRIMARY KEY,
    employment_id  TEXT NOT NULL UNIQUE,
    load_dt           TIMESTAMPTZ NOT NULL DEFAULT now(),
    record_source     TEXT NOT NULL DEFAULT 'raw.vacancy_details_wide'
);
COMMENT ON TABLE dv.H_Employment IS 'Hub: тип занятости (business key: employment.id)';

-- Опыт (experience)
CREATE TABLE IF NOT EXISTS dv.H_Experience (
    experience_hk   UUID NOT NULL PRIMARY KEY,
    experience_id   TEXT NOT NULL UNIQUE,
    load_dt         TIMESTAMPTZ NOT NULL DEFAULT now(),
    record_source   TEXT NOT NULL DEFAULT 'raw.vacancy_details_wide'
);
COMMENT ON TABLE dv.H_Experience IS 'Hub: требуемый опыт (business key: experience.id)';

-- Тип биллинга (billing_type)
CREATE TABLE IF NOT EXISTS dv.H_BillingType (
    billing_type_hk   UUID NOT NULL PRIMARY KEY,
    billing_type_id   TEXT NOT NULL UNIQUE,
    load_dt           TIMESTAMPTZ NOT NULL DEFAULT now(),
    record_source     TEXT NOT NULL DEFAULT 'raw.vacancy_details_wide'
);
COMMENT ON TABLE dv.H_BillingType IS 'Hub: тип биллинга вакансии (business key: billing_type.id)';

-- Форма занятости (employment_form)
CREATE TABLE IF NOT EXISTS dv.H_EmploymentForm (
    employment_form_hk   UUID NOT NULL PRIMARY KEY,
    employment_form_id   TEXT NOT NULL UNIQUE,
    load_dt              TIMESTAMPTZ NOT NULL DEFAULT now(),
    record_source        TEXT NOT NULL DEFAULT 'raw.vacancy_details_wide'
);
COMMENT ON TABLE dv.H_EmploymentForm IS 'Hub: форма занятости (business key: employment_form.id)';

-- Профессиональная роль (professional_roles[].id в API — целое число)
CREATE TABLE IF NOT EXISTS dv.H_ProfessionalRole (
    professional_role_hk   UUID NOT NULL PRIMARY KEY,
    professional_role_id   INT NOT NULL UNIQUE,
    load_dt                TIMESTAMPTZ NOT NULL DEFAULT now(),
    record_source          TEXT NOT NULL DEFAULT 'raw.vacancy_details_wide'
);
COMMENT ON TABLE dv.H_ProfessionalRole IS 'Hub: профессиональная роль (business key: professional_roles[].id)';

-- Навык (из key_skills[] — массив строк, BK = название навыка)
CREATE TABLE IF NOT EXISTS dv.H_Skill (
    skill_hk       UUID NOT NULL PRIMARY KEY,
    skill_name     TEXT NOT NULL UNIQUE,
    load_dt        TIMESTAMPTZ NOT NULL DEFAULT now(),
    record_source  TEXT NOT NULL DEFAULT 'raw.vacancy_details_wide'
);
COMMENT ON TABLE dv.H_Skill IS 'Hub: навык (business key: название из key_skills[])';
