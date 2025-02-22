-- Таблица customer
DROP TABLE IF EXISTS customer_20240101;
CREATE TABLE customer_20240101 (
    customer_id INT,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    gender VARCHAR(50),
    dob DATE,
    job_title VARCHAR(50),
    job_industry_category VARCHAR(50),
    wealth_segment VARCHAR(50),
    deceased_indicator VARCHAR(50),
    owns_car VARCHAR(30),
    address VARCHAR(100),
    postcode VARCHAR(30),
    state VARCHAR(50),
    country VARCHAR(50),
    property_valuation INT
);

-- Таблица transaction
DROP TABLE IF EXISTS transaction_20240101;
CREATE TABLE transaction_20240101 (
    transaction_id INT,
    product_id INT,
    customer_id INT,
    transaction_date DATE,
    online_order VARCHAR(30),
    order_status VARCHAR(30),
    brand VARCHAR(50),
    product_line VARCHAR(30),
    product_class VARCHAR(30),
    product_size VARCHAR(30),
    list_price FLOAT,
    standard_cost FLOAT
);

-- загрузили данные из csv файлов средствами dbeaver

/* 
(1 балл) Вывести все уникальные бренды, у которых стандартная стоимость выше 1500 долларов.
(1 балл) Вывести все подтвержденные транзакции за период '2017-04-01' по '2017-04-09' включительно.
(1 балл) Вывести все профессии у клиентов из сферы IT или Financial Services, которые начинаются с фразы 'Senior'.
(1 балл) Вывести все бренды, которые закупают клиенты, работающие в сфере Financial Services
(1 балл) Вывести 10 клиентов, которые оформили онлайн-заказ продукции из брендов 'Giant Bicycles', 'Norco Bicycles', 'Trek Bicycles'.
(1 балл) Вывести всех клиентов, у которых нет транзакций.
(2 балла) Вывести всех клиентов из IT, у которых транзакции с максимальной стандартной стоимостью.
(2 балла) Вывести всех клиентов из сферы IT и Health, у которых есть подтвержденные транзакции за период '2017-07-07' по '2017-07-17'.
 */
 
-- (1 балл) — Вывести все уникальные бренды, у которых стандартная стоимость выше 1500 долларов.
-- > таких 4 бренда
SELECT DISTINCT brand
FROM transaction_20240101
WHERE standard_cost > 1500;


-- (1 балл) Вывести все подтвержденные транзакции за период '2017-04-01' по '2017-04-09' включительно.
-- > 531 запись
SELECT *
FROM transaction_20240101
WHERE order_status = 'Approved'
  AND transaction_date BETWEEN '2017-04-01' AND '2017-04-09';


-- (1 балл) Вывести все профессии у клиентов из сферы IT или Financial Services, которые начинаются с фразы 'Senior'.
-- > 6 профессий
SELECT DISTINCT job_title
FROM customer_20240101
WHERE job_industry_category IN ('IT', 'Financial Services')
  AND job_title LIKE 'Senior%';

-- (1 балл) Вывести все бренды, которые закупают клиенты, работающие в сфере Financial Services
-- > 6 брендов + 1 noname
SELECT DISTINCT t.brand
FROM transaction_20240101 AS t
JOIN customer_20240101 AS c ON t.customer_id = c.customer_id
WHERE c.job_industry_category = 'Financial Services';

-- > Если нужны только существующие бренды
SELECT DISTINCT t.brand
FROM transaction_20240101 AS t
JOIN customer_20240101 AS c ON t.customer_id = c.customer_id
WHERE c.job_industry_category = 'Financial Services' and t.brand <> '';

-- > транзакции по товарам без бренда, у них также product_id = 0
SELECT *
FROM transaction_20240101 AS t
JOIN customer_20240101 AS c ON t.customer_id = c.customer_id
WHERE c.job_industry_category = 'Financial Services' and t.brand  = '';



-- (1 балл) Вывести 10 клиентов, которые оформили онлайн-заказ продукции из брендов 'Giant Bicycles', 'Norco Bicycles', 'Trek Bicycles'.
-- > 10 уникальных клиентов
SELECT DISTINCT c.customer_id,
       c.first_name,
       c.last_name
FROM transaction_20240101 AS t
JOIN customer_20240101 AS c ON t.customer_id = c.customer_id
WHERE t.online_order = 'True'
  AND t.brand IN ('Giant Bicycles', 'Norco Bicycles', 'Trek Bicycles')
LIMIT 10;


-- (1 балл) Вывести всех клиентов, у которых нет транзакций.
-- > 507 клиентов
SELECT c.*
FROM customer_20240101 AS c
LEFT JOIN transaction_20240101 AS t ON c.customer_id = t.customer_id
WHERE t.transaction_id IS NULL;


-- (2 балла) Вывести всех клиентов из IT, у которых транзакции с максимальной стандартной стоимостью.
-- > 9 клиентов
SELECT c.*
FROM customer_20240101 AS c
JOIN transaction_20240101 AS t
  ON c.customer_id = t.customer_id
WHERE 
	c.job_industry_category = 'IT' 
	and t.standard_cost = (select max(standard_cost) from transaction_20240101);

-- (2 балла) Вывести всех клиентов из сферы IT и Health, у которых есть подтвержденные транзакции за период '2017-07-07' по '2017-07-17'.
-- > 115 клиентов
SELECT DISTINCT c.customer_id,
       c.first_name,
       c.last_name
FROM transaction_20240101 AS t
JOIN customer_20240101 AS c
  ON t.customer_id = c.customer_id
WHERE c.job_industry_category IN ('IT', 'Health')
  AND t.order_status = 'Approved'
  AND t.transaction_date BETWEEN '2017-07-07' AND '2017-07-17';
 