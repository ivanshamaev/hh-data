-- Схема для сырых данных (raw)
CREATE SCHEMA IF NOT EXISTS raw;

-- Категории профессиональных ролей (API HH.ru professional_roles)
CREATE TABLE IF NOT EXISTS raw.categories (
    id          TEXT PRIMARY KEY,
    name        TEXT NOT NULL,
    inserted_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE raw.categories IS 'Категории из API https://api.hh.ru/professional_roles';

-- Роли внутри категорий (связь many-to-many: одна роль может быть в нескольких категориях)
CREATE TABLE IF NOT EXISTS raw.roles (
    id                      TEXT NOT NULL,
    category_id             TEXT NOT NULL REFERENCES raw.categories(id) ON DELETE CASCADE,
    name                    TEXT NOT NULL,
    is_default              BOOLEAN NOT NULL DEFAULT false,
    search_deprecated       BOOLEAN NOT NULL DEFAULT false,
    select_deprecated       BOOLEAN NOT NULL DEFAULT false,
    accept_incomplete_resumes BOOLEAN NOT NULL DEFAULT false,
    inserted_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id, category_id)
);

COMMENT ON TABLE raw.roles IS 'Профессиональные роли из API HH.ru (развёрнуто из categories.roles)';
