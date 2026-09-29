
--EXERCICI 1
--Crear Dataset Físic sprint3_silver
CREATE SCHEMA IF NOT EXISTS`sprint3-analytics-cristina.sprint3_silver`
OPTIONS(
  location = 'EU'
);



--EXERCICI 2
--Escriu i executa les sentències CREATE EXTERNAL TABLE per connectar els següents fitxers al dataset sprint3_bronze. Para molta atenció a les "Notes Tècniques", ja que no tots els arxius tenen el mateix format.

--Cargamos tabla transactions:
CREATE EXTERNAL TABLE IF NOT EXISTS `sprint3-analytics-cristina.sprint3_bronze.transactions_raw`
  OPTIONS (
    format ='CSV',
    uris = ['gs://bootcamp-data-analytics-public/ERP/transactions.csv'],
    field_delimiter = ';');


--Mostramos la tabla:
SELECT *
FROM sprint3-analytics-cristina.sprint3_bronze.transactions_raw
LIMIT 20;


--Cargamos la tabla companies:
CREATE EXTERNAL TABLE IF NOT EXISTS `sprint3-analytics-cristina.sprint3_bronze.companies_raw` (
  company_id STRING,
  company_name STRING,
  phone STRING,
  email STRING,
  country STRING,
  website STRING,
  )
  OPTIONS (
    format ='CSV',
    skip_leading_rows = 1,
    uris = ['gs://bootcamp-data-analytics-public/ERP/companies.csv']);

--Mostramos tabla:
SELECT *
FROM sprint3-analytics-cristina.sprint3_bronze.companies_raw
LIMIT 20;


--Cargamos la tabla american_users_raw:
CREATE EXTERNAL TABLE IF NOT EXISTS `sprint3-analytics-cristina.sprint3_bronze.american_users_raw`
  OPTIONS (
    format ='CSV',
    uris = ['gs://bootcamp-data-analytics-public/CRM/american_users.csv']
    );


--Mostramos tabla:
SELECT *
FROM sprint3-analytics-cristina.sprint3_bronze.american_users_raw
LIMIT 20;


--Cargamos la tabla european_users_raw:
CREATE EXTERNAL TABLE IF NOT EXISTS `sprint3-analytics-cristina.sprint3_bronze.european_users_raw`
  OPTIONS (
    format ='CSV',
    uris = ['gs://bootcamp-data-analytics-public/CRM/european_users.csv']
   );


--Mostramos tabla:
SELECT*
FROM sprint3-analytics-cristina.sprint3_bronze.european_users_raw
LIMIT 20;


--Cargamos la tabla credit_cards:
CREATE EXTERNAL TABLE IF NOT EXISTS `sprint3-analytics-cristina.sprint3_bronze.credit_cards_raw`
  OPTIONS (
    format ='CSV',
    uris = ['gs://bootcamp-data-analytics-public/CRM/credit_cards.csv']
   );



--Mostramos tabla:
SELECT*
FROM sprint3-analytics-cristina.sprint3_bronze.credit_cards_raw
LIMIT 20;



--EXERCICI 3
--Falta el catàleg de Productes. Aquesta informació no és al Data Lake, utilitza el fitxer products.csv de l'sprint 2.

--> Cargamos la tabla products.csv manualmente mediante 'upload'. Hago pantallazos en el PDF



--EXERCICI 4
--Les consultes sobre el Data Lake van lentes. Has de demostrar al teu mànager la diferència de rendiment entre treballar amb fitxers externs i treballar amb taules natives de BigQuery.

--a) Materialització de Dades (Assistit per IA)

CREATE OR REPLACE TABLE `sprint3-analytics-cristina.sprint3_bronze.transactions_raw_native` AS
SELECT * FROM `sprint3-analytics-cristina.sprint3_bronze.transactions_raw`;


--b) Auditoria de Costos

--Con tabla externa:
SELECT id
FROM `sprint3-analytics-cristina.sprint3_bronze.transactions_raw`;

--Con tabala nativa
SELECT id
FROM `sprint3-analytics-cristina.sprint3_bronze.transactions_raw_native`;


--c) El perill del LIMIT

--Con tabla externa:
SELECT id
FROM `sprint3-analytics-cristina.sprint3_bronze.transactions_raw`
LIMIT 10;

--Con tabala nativa
SELECT id
FROM `sprint3-analytics-cristina.sprint3_bronze.transactions_raw_native`
LIMIT 10;



--EXERCICI 5

--Exercici 5: Adaptació de Sintaxi (Reporting)
--El teu cap vol saber quins van ser els 5 dies amb més ingressos de l'any 2021.

SELECT DATE(timestamp) as fecha , ROUND(SUM(amount),2) AS ingresos
FROM `sprint3-analytics-cristina.sprint3_bronze.transactions_raw_native` t
WHERE EXTRACT(YEAR FROM timestamp) = 2021
AND declined = 0
GROUP BY fecha
ORDER BY ingresos DESC
LIMIT 5;



--EXERCICI 6

--Llista el nom, país i data de les transaccions realitzades per empreses que van fer operacions entre 100 i 200 euros en alguna d'aquestes dates: 29-04-2015, 20-07-2018 o 13-03-2024.

SELECT c.company_name, c.country, DATE(timestamp) as fecha , t.amount
FROM `sprint3-analytics-cristina.sprint3_bronze.transactions_raw_native` t
JOIN `sprint3-analytics-cristina.sprint3_bronze.companies_raw` c
ON t.business_id = c.company_id
WHERE DATE(timestamp) IN ('2015-04-29', '2018-07-20', '2024-03-13')
AND t.amount BETWEEN 100 AND 200
AND t.declined = 0
ORDER BY DATE(timestamp);



--NIVELL 2
--Les dades brutes tenen problemes de qualitat (símbols de moneda, usuaris duplicats, dates incorrectes). Actua com a Data Engineer per netejar-ho tot.

--EXERCICI 1
--Crearem la capa neta ("Silver") per als productes

CREATE OR REPLACE TABLE `sprint3-analytics-cristina.sprint3_silver.products_clean` AS
SELECT 
id AS product_id,
product_name as name,
SAFE_CAST(price AS FLOAT64) as price,
colour,
weight,
SAFE_CAST(REGEXP_REPLACE(warehouse_id, r'WH-', '') AS INT64) AS warehouse_id,
category,
brand,
cost,
launch_date,
FROM `sprint3-analytics-cristina.sprint3_bronze.products_raw`;



--EXERCICI 2
--Creació de Transaccions Netes (Capa Silver)
CREATE OR REPLACE TABLE `sprint3-analytics-cristina.sprint3_silver.transactions_clean` AS
SELECT 
id AS transaction_id,
card_id,
business_id,
IFNULL(SAFE_CAST(amount AS FLOAT64), 0) AS amount,
SAFE_CAST(timestamp AS TIMESTAMP) AS timestamp,
declined,
ARRAY(
        SELECT SAFE_CAST(elemento AS INT64) 
        FROM UNNEST(SPLIT(product_ids, ',')) AS elemento
    ) AS product_ids,
user_id,
SAFE_CAST(lat AS FLOAT64)AS lat,
SAFE_CAST(longitude AS FLOAT64) AS longitude
FROM `sprint3-analytics-cristina.sprint3_bronze.transactions_raw`;



--EXERCICI 3
--Unificació d'Usuaris (UNION)

CREATE OR REPLACE TABLE `sprint3-analytics-cristina.sprint3_silver.users_combined` AS
SELECT id AS user_id, name,surname, phone, email, birth_date, country, city, postal_code, address,'european' AS origin
FROM `sprint3-analytics-cristina.sprint3_bronze.european_users_raw`
UNION ALL 
SELECT id AS user_id, name, surname, phone, email, birth_date, country, city, postal_code, address, 'american' AS origin
FROM `sprint3-analytics-cristina.sprint3_bronze.american_users_raw`;



--EXERCICI 4
--Materialització de Companyies i Targetes de Crèdit

--Creamos coompanies_clean
CREATE OR REPLACE TABLE  `sprint3-analytics-cristina.sprint3_silver.companies_clean`AS
SELECT *
FROM `sprint3-analytics-cristina.sprint3_bronze.companies_raw` ;


--Creamos credit_cards_clean
CREATE OR REPLACE TABLE  `sprint3-analytics-cristina.sprint3_silver.credit_cards_clean`AS
SELECT id AS card_id, user_id, iban, pan, pin, cvv, track1, track2, expiring_date
FROM `sprint3-analytics-cristina.sprint3_bronze.credit_cards_raw`;



--NIVELL 3
--EXERCICI 1 La Vista de Màrqueting (Lògica de Negoci)

CREATE OR REPLACE VIEW  sprint3-analytics-cristina.sprint3_gold.v_marketing_kpis AS
SELECT c.company_name,c.phone, c.country, t.user_id, ROUND(AVG(t.amount),2) AS media, CASE
              WHEN AVG(t.amount)  > 260 THEN 'Premium'
              ELSE 'Standard'
              END AS client_tier
FROM sprint3-analytics-cristina.sprint3_silver.companies_clean c
JOIN sprint3-analytics-cristina.sprint3_silver.transactions_clean t
ON c.company_id = t.business_id
WHERE t.declined = 0
GROUP BY c.company_name,c.phone, c.country, t.user_id;   


--Consulta sobre la vista:
SELECT *, 
FROM sprint3-analytics-cristina.sprint3_gold.v_marketing_kpis v
ORDER BY client_tier= 'Premium' DESC, media DESC;



--EXERCICI 2 Rànquing de Productes (La Potència dels Arrays)

CREATE OR REPLACE TABLE sprint3-analytics-cristina.sprint3_gold.product_sales_ranking AS 
SELECT p.product_id, p.name, p.price, p.colour, COUNT(sold_product_id) AS total_sold
FROM sprint3-analytics-cristina.sprint3_silver.products_clean p
LEFT JOIN (
    SELECT *
    FROM sprint3-analytics-cristina.sprint3_silver.transactions_clean t,
    UNNEST(t.product_ids) AS sold_product_id
    WHERE t.declined = 0
) ventas
ON p.product_id = ventas.sold_product_id
GROUP BY p.product_id, p.name, p.price, p.colour
ORDER BY total_sold DESC;



--EXERCICI 3  Exportació de Resultats

--Hacemos consulta para poder descargar la tabla a un CSV
SELECT*
FROM sprint3-analytics-cristina.sprint3_gold.product_sales_ranking
ORDER BY total_sold DESC;



