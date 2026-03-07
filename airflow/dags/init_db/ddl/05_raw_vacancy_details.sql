-- Детали вакансий HH.ru (полный JSON по GET /vacancies/{id}). Одна запись на вакансию.
CREATE TABLE IF NOT EXISTS raw.vacancy_details (
    id          TEXT PRIMARY KEY,
    payload     JSONB NOT NULL,
    inserted_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE raw.vacancy_details IS 'Детальный ответ API GET /vacancies/{id} в формате JSON';

-- Отметки о загрузке: по ним определяем, какие вакансии уже выгружены в vacancy_details (инкремент).
CREATE TABLE IF NOT EXISTS raw.vacancy_details_loaded (
    vacancy_id  TEXT PRIMARY KEY,
    loaded_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE raw.vacancy_details_loaded IS 'Вакансии, для которых уже загружены детали в raw.vacancy_details';

-- Служебная таблица для батчей: список id вакансий по batch_id (заполняется перед загрузкой, читается mapped-задачами).
CREATE TABLE IF NOT EXISTS raw.vacancy_details_batch (
    batch_id    INT NOT NULL,
    vacancy_id  TEXT NOT NULL
);

COMMENT ON TABLE raw.vacancy_details_batch IS 'Служебная: батчи vacancy_id для параллельной загрузки деталей (очищается при каждом запуске DAG)';

CREATE INDEX IF NOT EXISTS ix_vacancy_details_batch_batch_id
    ON raw.vacancy_details_batch (batch_id);
