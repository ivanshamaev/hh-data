-- Вакансии HH.ru по поисковым запросам (ключевые фразы). Полный JSON + поля для обозначения.
CREATE TABLE IF NOT EXISTS raw.vacancies_search (
    id                      TEXT NOT NULL,
    search_query            TEXT NOT NULL,
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
    employer_logo_urls_240   TEXT,
    professional_roles_id    TEXT,
    professional_roles_name  TEXT,
    inserted_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id, search_query)
);

COMMENT ON TABLE raw.vacancies_search IS 'Вакансии HH.ru по поисковым запросам (параметр text в API /vacancies)';
COMMENT ON COLUMN raw.vacancies_search.search_query IS 'Поисковая фраза, по которой нашли вакансию';
COMMENT ON COLUMN raw.vacancies_search.professional_roles_id IS 'id первой роли из payload.professional_roles[0]';
COMMENT ON COLUMN raw.vacancies_search.professional_roles_name IS 'name первой роли из payload.professional_roles[0]';
