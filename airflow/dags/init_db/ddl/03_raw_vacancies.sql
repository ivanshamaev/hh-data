-- Вакансии HH.ru (Москва по профессиональным ролям). Полный JSON + поля для обозначения.
CREATE TABLE IF NOT EXISTS raw.vacancies (
    id                      TEXT NOT NULL,
    professional_role_id    TEXT NOT NULL,
    payload                 JSONB NOT NULL,
    name                    TEXT,
    area_name               TEXT,
    salary_from             NUMERIC,
    salary_to               NUMERIC,
    currency                TEXT,
    published_at            TIMESTAMPTZ,
    employer_id             TEXT,
    employer_name           TEXT,
    alternate_url           TEXT,
    type_id                 TEXT,
    type_name               TEXT,
    vacancy_url             TEXT,
    employer_url            TEXT,
    employer_logo_urls_240  TEXT,
    inserted_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id, professional_role_id)
);

COMMENT ON TABLE raw.vacancies IS 'Вакансии HH.ru (API /vacancies), Москва, по ролям из raw.roles';
COMMENT ON COLUMN raw.vacancies.payload IS 'Исходный JSON ответа API по вакансии';
COMMENT ON COLUMN raw.vacancies.professional_role_id IS 'Роль из raw.roles, по которой запрашивали вакансии';
