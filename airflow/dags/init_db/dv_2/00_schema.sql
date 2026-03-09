-- Raw Data Vault 2.0: схема для хабов, линков и спутников по вакансиям (источник: raw.vacancy_details / raw.vacancy_details_wide).
CREATE SCHEMA IF NOT EXISTS dv;

COMMENT ON SCHEMA dv IS 'Raw Data Vault 2.0: хабы, линки, спутники по вакансиям HH.ru';

-- Преобразование MD5(business_key) в UUID для полей _hk (128 бит = 32 hex, формат 8-4-4-4-12).
CREATE OR REPLACE FUNCTION dv.md5_as_uuid(t text)
RETURNS uuid
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT (
        substr(md5(t), 1, 8) || '-' ||
        substr(md5(t), 9, 4) || '-' ||
        substr(md5(t), 13, 4) || '-' ||
        substr(md5(t), 17, 4) || '-' ||
        substr(md5(t), 21, 12)
    )::uuid;
$$;

COMMENT ON FUNCTION dv.md5_as_uuid(text) IS 'Детерминированный hash key: MD5(text) в формате UUID для полей _hk';
