set datestyle = 'iso, dmy';

-- создание таблиц для импорта всех данных без преобразования для исследования

create table raw_customer (
    customer_id             varchar(255),
    first_name              varchar(255),
    last_name               varchar(255),
    gender                  varchar(255),
    dob                     varchar(255),
    job_title               varchar(255),
    job_industry_category   varchar(255),
    wealth_segment          varchar(255),
    deceased_indicator      varchar(255),
    owns_car                varchar(255),
    address                 varchar(255),
    postcode                varchar(255),
    state                   varchar(255),
    country                 varchar(255),
    property_valuation      varchar(255)
);

create table raw_transaction (
    transaction_id    varchar(255),
    product_id        varchar(255),
    customer_id       varchar(255),
    transaction_date  varchar(255),
    online_order      varchar(255),
    order_status      varchar(255),
    brand             varchar(255),
    product_line      varchar(255),
    product_class     varchar(255),
    product_size      varchar(255),
    list_price        varchar(255),
    standard_cost     varchar(255)
);

/*
далее нужно выполнить импорт данных:
импорт через dbreaver или 
load_data.py (sqlaclhemy меняет типы колонок в таблицах в бд)
*/

create table t_customer (
    customer_id      		serial primary key,
    customer_id_old         varchar(10),
    first_name              varchar(50),
    last_name               varchar(50),
    gender                  varchar(10),
    dob                     date,
    job_title               varchar(100),
    job_industry_category   varchar(50),
    wealth_segment          varchar(50),
    deceased_indicator      char(1),
    owns_car                varchar(3),
    address                 varchar(100),
    postcode                varchar(4),
    state                   varchar(50),
    country                 varchar(20),
    property_valuation      int
);

-- first_name, last_name, dob создают уникальную комбинацию

insert into t_customer (
    customer_id_old, 
    first_name, last_name, gender, 
    dob, 
    job_title, job_industry_category, wealth_segment, 
    deceased_indicator, owns_car, address, postcode, state, country, 
    property_valuation
)
select distinct on (first_name, last_name, dob)
    customer_id,
    first_name, last_name, gender, 
    to_date(dob, 'yyyy-mm-dd'), 
    job_title, job_industry_category, wealth_segment, 
    deceased_indicator, owns_car, address, postcode, state, country, 
    property_valuation::int
from raw_customer;

-- добавим запись 5034, т.к. она есть в transactions
insert into t_customer (customer_id_old)
values (5034);

/*
 *  list_price и standard_cost я решил не переносить, т.к. они могут меняться со временем и не совсем понятна их сущность
 * для уникальности я включил также product_id, т.к. опять же неизвестно почему они могут быть разные. 
 * возможно, это реально разные продукты и забыли добавить отличительные черты, а может быть криво добавили данные
 * в любом случае информацию лучше не терять, а если окажется, что одинаковые товары с разным product_id - можно будет обновить.
*/

create table t_product (
    product_id      serial primary key,
    product_id_old  varchar(10),
    brand           varchar(100),
    product_line    varchar(100),
    product_class   varchar(100),
    product_size    varchar(50)
);

-- выделим product

insert into t_product (product_id_old, brand, product_line, product_class, product_size)
select distinct
    product_id, 
    brand, product_line, product_class, product_size 
from raw_transaction;

-- создадим таблицу транзакций 

create table t_transaction (
    transaction_id		serial primary key,
    transaction_id_old	varchar(10),
    product_id			int not null,
    customer_id			int,
    transaction_date	date not null,
    online_order		boolean,
    order_status		varchar(50) not null,
    list_price        float8 not null,
    standard_cost     float8,
    foreign key (product_id) references t_product(product_id),
    foreign key (customer_id) references t_customer(customer_id)
);

-- выделим аккуратно transaction так, чтобы customer правильно подцепился

insert into t_transaction (
    transaction_id_old, 
    product_id, 
    customer_id, 
    transaction_date, 
    online_order, 
    order_status, 
    list_price, 
    standard_cost
)
select
    r.transaction_id,
    p.product_id,
    c.customer_id,
    to_date(r.transaction_date, 'yyyy-mm-dd') as transaction_date,
    cast(nullif(r.online_order, '') as boolean),
    r.order_status, 
    cast(nullif(r.list_price, '') as float8), 
    cast(nullif(r.standard_cost, '') as float8)
from raw_transaction r
join t_product p
on (r.product_id = p.product_id_old or (r.product_id is null and p.product_id_old is null))
and (r.brand = p.brand or (r.brand is null and p.brand is null))
and (r.product_line = p.product_line or (r.product_line is null and p.product_line is null))
and (r.product_class = p.product_class or (r.product_class is null and p.product_class is null))
and (r.product_size = p.product_size or (r.product_size is null and p.product_size is null))
join t_customer c
on r.customer_id = c.customer_id_old;

-- проверка таблицы customer, будет лишняя запись 5034, которую мы добавили ранее
select 
    (select count(*) from (select distinct first_name, last_name, dob from raw_customer) as unique_raw) as raw_count,
    (select count(*) from t_customer) as t_customer_count;


-- проверка таблицы customer, будет лишняя запись 5034, которую мы добавили ранее 
select 
    customer_id::text, 
    first_name::text, 
    last_name::text, 
    gender::text, 
    to_date(dob, 'yyyy-mm-dd') as dob, 
    job_title::text, 
    job_industry_category::text, 
    wealth_segment::text, 
    deceased_indicator::text, 
    owns_car::text, 
    address::text, 
    postcode::text, 
    state::text, 
    country::text, 
    property_valuation::text
from raw_customer
except
select 
    customer_id_old::text, 
    first_name::text, 
    last_name::text, 
    gender::text, 
    dob, 
    job_title::text, 
    job_industry_category::text, 
    wealth_segment::text, 
    deceased_indicator::text, 
    owns_car::text, 
    address::text, 
    postcode::text, 
    state::text, 
    country::text, 
    property_valuation::text
from t_customer
union all
select 
    customer_id_old::text, 
    first_name::text, 
    last_name::text, 
    gender::text, 
    dob, 
    job_title::text, 
    job_industry_category::text, 
    wealth_segment::text, 
    deceased_indicator::text, 
    owns_car::text, 
    address::text, 
    postcode::text, 
    state::text, 
    country::text, 
    property_valuation::text
from t_customer
except
select 
    customer_id::text, 
    first_name::text, 
    last_name::text, 
    gender::text, 
    to_date(dob, 'yyyy-mm-dd') as dob, 
    job_title::text, 
    job_industry_category::text, 
    wealth_segment::text, 
    deceased_indicator::text, 
    owns_car::text, 
    address::text, 
    postcode::text, 
    state::text, 
    country::text, 
    property_valuation::text
from raw_customer;

-- проверка transactions
select 
    (select count(*) from (select distinct transaction_id from raw_transaction) as unique_raw) as raw_count,
    (select count(*) from t_transaction) as t_transaction_count;

-- проверка transactions
select 
    transaction_id::text, 
    customer_id::text, 
    product_id::text, 
    to_char(to_date(transaction_date, 'yyyy-mm-dd'), 'yyyy-mm-dd') as transaction_date,
    lower(nullif(online_order, ''))::text, 
    order_status::text, 
    nullif(list_price, '')::numeric::text as list_price, 
    nullif(standard_cost, '')::numeric::text as standard_cost
from raw_transaction
except
select 
    transaction_id_old::text, 
    c.customer_id_old::text, 
    p.product_id_old::text, 
    to_char(transaction_date, 'yyyy-mm-dd') as transaction_date,
    nullif(online_order::text, '')::text, 
    order_status::text, 
    list_price::text, 
    standard_cost::text
from t_transaction t
join t_product p on t.product_id = p.product_id
join t_customer c on t.customer_id = c.customer_id
union all
select 
    transaction_id_old::text, 
    c.customer_id_old::text, 
    p.product_id_old::text, 
    to_char(transaction_date, 'yyyy-mm-dd') as transaction_date,
    nullif(online_order::text, '')::text, 
    order_status::text, 
    list_price::text, 
    standard_cost::text
from t_transaction t
join t_product p on t.product_id = p.product_id
join t_customer c on t.customer_id = c.customer_id
except
select 
    transaction_id::text, 
    customer_id::text, 
    product_id::text, 
    to_char(to_date(transaction_date, 'yyyy-mm-dd'), 'yyyy-mm-dd') as transaction_date,
    lower(nullif(online_order, ''))::text, 
    order_status::text, 
    nullif(list_price, '')::numeric::text as list_price, 
    nullif(standard_cost, '')::numeric::text as standard_cost
from raw_transaction;