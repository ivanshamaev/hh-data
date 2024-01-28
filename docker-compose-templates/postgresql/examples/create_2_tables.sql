-- Создаем таблицу table_1
CREATE TABLE mydata.table_1 (
    datetime TIMESTAMP,
    category_1 VARCHAR(255),
    category_2 VARCHAR(255),
    product VARCHAR(255),
    customer VARCHAR(255),
    item_cnt INT,
    item_price NUMERIC
);

-- Создаем таблицу table_2
CREATE TABLE mydata.table_2 (
    datetime TIMESTAMP,
    category_1 VARCHAR(255),
    category_2 VARCHAR(255),
    product VARCHAR(255),
    customer VARCHAR(255),
    city VARCHAR(255),
    region VARCHAR(255),
    item_cnt INT,
    item_price NUMERIC
);

-- Генерируем данные для table_1
INSERT INTO mydata.table_1 (datetime, category_1, category_2, product, customer, item_cnt, item_price)
SELECT
    NOW() - INTERVAL '1 day' * (random() * 365)::int,
    'Category1_' || (random() * 5 + 1)::int,
    'Category2_' || (random() * 10 + 1)::int,
    'Product_' || (random() * 50 + 1)::int,
    'Customer_' || (random() * 1000 + 1)::int,
    (random() * 10 + 1)::int,
    (random() * 100 + 1)::numeric(10, 2)
FROM generate_series(1, 1000);

-- Генерируем данные для table_2
INSERT INTO mydata.table_2 (datetime, category_1, category_2, product, customer, city, region, item_cnt, item_price)
SELECT
    NOW() - INTERVAL '1 day' * (random() * 365)::int,
    'Category1_' || (random() * 5 + 1)::int,
    'Category2_' || (random() * 10 + 1)::int,
    'Product_' || (random() * 50 + 1)::int,
    'Customer_' || (random() * 1000 + 1)::int,
    'City_' || (random() * 3 + 1)::int,
    'Region_' || (random() * 5 + 1)::int,
    (random() * 10 + 1)::int,
    (random() * 100 + 1)::numeric(10, 2)
FROM generate_series(1, 1000);
