-- Дедупликация raw.vacancies_search: одна запись на id (с максимальным inserted_at).
-- Используется для загрузки деталей по id из поиска без дублей.
CREATE OR REPLACE VIEW raw.vacancies_search_dedup AS
SELECT DISTINCT ON (id)
    id,
    search_query,
    payload,
    name,
    area_name,
    salary_from,
    salary_to,
    currency,
    published_at,
    employer_id,
    employer_name,
    alternate_url,
    type_id,
    type_name,
    vacancy_url,
    employer_url,
    employer_logo_urls_240,
    professional_roles_id,
    professional_roles_name,
    inserted_at
FROM raw.vacancies_search
ORDER BY id, inserted_at DESC;

COMMENT ON VIEW raw.vacancies_search_dedup IS 'Одна запись на id вакансии (последняя по inserted_at); источник для загрузки деталей из vacancies_search';
