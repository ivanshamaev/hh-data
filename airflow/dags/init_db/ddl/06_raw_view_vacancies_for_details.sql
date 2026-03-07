-- View: вакансии только по выбранным ролям (программист, разработчик, аналитик и т.п.).
-- Используется для загрузки деталей: берём id из этой вьюшки, дельта с raw.vacancy_details_loaded.
CREATE OR REPLACE VIEW raw.vacancies_for_details AS
SELECT r.name AS role_name, v.*
FROM raw.vacancies v
JOIN raw.roles r ON v.professional_role_id = r.id
WHERE r.name IN (
    SELECT DISTINCT name
    FROM raw.roles
    WHERE name ILIKE '%программист%'
       OR name ILIKE '%разработчик%'
       OR name ILIKE '%аналити%'
       OR name ILIKE '%разработ%'
       OR name ILIKE '%тестировщик%'
       OR name ILIKE '%DevOps-инженер%'
       OR name ILIKE '%Системный администратор%'
       OR name ILIKE '%Сетевой инженер%'
       OR name ILIKE '%Системный инженер%'
       OR name ILIKE '%Дата-сайентист%'
       OR name ILIKE '%Технический директор (CTO)%'
       OR name ILIKE '%Директор по информационным технологиям (CIO)%'
);

COMMENT ON VIEW raw.vacancies_for_details IS 'Вакансии по выбранным ролям (программист, разработчик, аналитик, DevOps, сисадмин, CTO, CIO и др.) для загрузки деталей; дельта с vacancy_details_loaded';
