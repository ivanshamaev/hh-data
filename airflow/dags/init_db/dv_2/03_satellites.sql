-- Raw DV 2.0: спутники (атрибуты и история по хабам). PK = parent_hk + load_dt (или parent_hk + load_dt + record_source при мультиисточнике).

-- Спутник вакансии: все атрибуты из wide-таблицы, привязанные к моменту загрузки
CREATE TABLE IF NOT EXISTS dv.S_Vacancy_Details (
    vacancy_hk        TEXT NOT NULL REFERENCES dv.H_Vacancy(vacancy_hk),
    load_dt           TIMESTAMPTZ NOT NULL DEFAULT now(),
    record_source     TEXT NOT NULL DEFAULT 'raw.vacancy_details_wide',
    name              TEXT,
    type_id           TEXT,
    type_name         TEXT,
    salary_from       NUMERIC,
    salary_to         NUMERIC,
    salary_currency   TEXT,
    salary_gross      BOOLEAN,
    address_raw       TEXT,
    address_city      TEXT,
    address_street    TEXT,
    address_building  TEXT,
    address_lat       NUMERIC,
    address_lng       NUMERIC,
    address_metro_station_name TEXT,
    published_at      TIMESTAMPTZ,
    created_at        TIMESTAMPTZ,
    initial_created_at TIMESTAMPTZ,
    alternate_url     TEXT,
    description       TEXT,
    description_clean TEXT,
    premium           BOOLEAN,
    archived          BOOLEAN,
    has_test          BOOLEAN,
    response_letter_required BOOLEAN,
    work_schedule_by_days    JSONB,
    work_schedule_by_days_name TEXT,
    working_hours     JSONB,
    working_hours_name TEXT,
    professional_roles_name  TEXT,
    updated_at        TIMESTAMPTZ,
    PRIMARY KEY (vacancy_hk, load_dt)
);
COMMENT ON TABLE dv.S_Vacancy_Details IS 'Satellite: атрибуты вакансии по загрузке (источник: raw.vacancy_details_wide)';

-- Спутник региона: название и url (из контекста вакансии)
CREATE TABLE IF NOT EXISTS dv.S_Area_Details (
    area_hk       TEXT NOT NULL REFERENCES dv.H_Area(area_hk),
    load_dt       TIMESTAMPTZ NOT NULL DEFAULT now(),
    record_source TEXT NOT NULL DEFAULT 'raw.vacancy_details_wide',
    area_name     TEXT,
    area_url      TEXT,
    PRIMARY KEY (area_hk, load_dt)
);
COMMENT ON TABLE dv.S_Area_Details IS 'Satellite: атрибуты региона (name, url)';

-- Спутник работодателя
CREATE TABLE IF NOT EXISTS dv.S_Employer_Details (
    employer_hk      TEXT NOT NULL REFERENCES dv.H_Employer(employer_hk),
    load_dt          TIMESTAMPTZ NOT NULL DEFAULT now(),
    record_source    TEXT NOT NULL DEFAULT 'raw.vacancy_details_wide',
    employer_name    TEXT,
    employer_url     TEXT,
    employer_logo_240 TEXT,
    PRIMARY KEY (employer_hk, load_dt)
);
COMMENT ON TABLE dv.S_Employer_Details IS 'Satellite: атрибуты работодателя';

-- Спутник графика работы
CREATE TABLE IF NOT EXISTS dv.S_Schedule_Details (
    schedule_hk    TEXT NOT NULL REFERENCES dv.H_Schedule(schedule_hk),
    load_dt        TIMESTAMPTZ NOT NULL DEFAULT now(),
    record_source  TEXT NOT NULL DEFAULT 'raw.vacancy_details_wide',
    schedule_name  TEXT,
    PRIMARY KEY (schedule_hk, load_dt)
);
COMMENT ON TABLE dv.S_Schedule_Details IS 'Satellite: название графика';

-- Спутник типа занятости
CREATE TABLE IF NOT EXISTS dv.S_Employment_Details (
    employment_hk    TEXT NOT NULL REFERENCES dv.H_Employment(employment_hk),
    load_dt          TIMESTAMPTZ NOT NULL DEFAULT now(),
    record_source    TEXT NOT NULL DEFAULT 'raw.vacancy_details_wide',
    employment_name  TEXT,
    PRIMARY KEY (employment_hk, load_dt)
);
COMMENT ON TABLE dv.S_Employment_Details IS 'Satellite: название типа занятости';

-- Спутник опыта
CREATE TABLE IF NOT EXISTS dv.S_Experience_Details (
    experience_hk    TEXT NOT NULL REFERENCES dv.H_Experience(experience_hk),
    load_dt          TIMESTAMPTZ NOT NULL DEFAULT now(),
    record_source    TEXT NOT NULL DEFAULT 'raw.vacancy_details_wide',
    experience_name  TEXT,
    PRIMARY KEY (experience_hk, load_dt)
);
COMMENT ON TABLE dv.S_Experience_Details IS 'Satellite: название уровня опыта';

-- Спутник типа биллинга
CREATE TABLE IF NOT EXISTS dv.S_BillingType_Details (
    billing_type_hk   TEXT NOT NULL REFERENCES dv.H_BillingType(billing_type_hk),
    load_dt           TIMESTAMPTZ NOT NULL DEFAULT now(),
    record_source     TEXT NOT NULL DEFAULT 'raw.vacancy_details_wide',
    billing_type_name TEXT,
    PRIMARY KEY (billing_type_hk, load_dt)
);
COMMENT ON TABLE dv.S_BillingType_Details IS 'Satellite: название типа биллинга';

-- Спутник формы занятости
CREATE TABLE IF NOT EXISTS dv.S_EmploymentForm_Details (
    employment_form_hk   TEXT NOT NULL REFERENCES dv.H_EmploymentForm(employment_form_hk),
    load_dt              TIMESTAMPTZ NOT NULL DEFAULT now(),
    record_source        TEXT NOT NULL DEFAULT 'raw.vacancy_details_wide',
    employment_form_name TEXT,
    PRIMARY KEY (employment_form_hk, load_dt)
);
COMMENT ON TABLE dv.S_EmploymentForm_Details IS 'Satellite: название формы занятости';

-- Спутник профессиональной роли (название из professional_roles[].name)
CREATE TABLE IF NOT EXISTS dv.S_ProfessionalRole_Details (
    professional_role_hk   TEXT NOT NULL REFERENCES dv.H_ProfessionalRole(professional_role_hk),
    load_dt                TIMESTAMPTZ NOT NULL DEFAULT now(),
    record_source          TEXT NOT NULL DEFAULT 'raw.vacancy_details_wide',
    professional_role_name TEXT,
    PRIMARY KEY (professional_role_hk, load_dt)
);
COMMENT ON TABLE dv.S_ProfessionalRole_Details IS 'Satellite: название профессиональной роли';
