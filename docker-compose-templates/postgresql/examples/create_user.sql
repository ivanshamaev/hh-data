-- Создаем схему mydata, если её нет
CREATE SCHEMA IF NOT EXISTS mydata;

-- Создаем пользователя
CREATE USER user4select WITH PASSWORD 'password';

-- Даем права на чтение ко всем таблицам в базе данных postgres
GRANT SELECT ON ALL TABLES IN SCHEMA mydata TO user4select;