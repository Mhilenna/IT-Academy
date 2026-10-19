
-- NIVELL 1
-- EXERCICI 1 Consulta sobre Taula no Optimitzada (Diagnòstic)

SELECT *
FROM sprint3-analytics-cristina.sprint3_silver.transactions_clean t
JOIN sprint3-analytics-cristina.sprint3_silver.companies_clean c
  ON t.business_id = c.company_id
WHERE
  DATE(timestamp) = DATE'2022-03-12'
  AND c.country = 'Germany';


-- EXERCICI 2 Re-arquitectura i Optimització de l'Emmagatzematge (Partition & Cluster)
-- PAS 1

CREATE OR REPLACE TABLE `sprint3-analytics-cristina.sprint3_silver.transactions_recent`
AS
SELECT
  * EXCEPT (timestamp),
  TIMESTAMP_SUB(
    CURRENT_TIMESTAMP(),
    INTERVAL CAST(RAND() * 5184000 AS INT64) SECOND) AS timestamp
FROM `sprint3-analytics-cristina.sprint3_silver.transactions_clean`;

-- PAS 2
CREATE OR REPLACE TABLE `sprint3-analytics-cristina.sprint3_gold.fact_transactions_optimized`
  PARTITION BY
    DATE(timestamp)
  CLUSTER BY business_id
AS
SELECT *
FROM `sprint3-analytics-cristina.sprint3_silver.transactions_recent`;




-- EXERCICI 3 La Prova del Cotó (Benchmark)
-- Taula no optimitzada:
SELECT *
FROM `sprint3-analytics-cristina.sprint3_silver.transactions_recent`
WHERE timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY);

-- Taula optimitzada:
SELECT *
FROM `sprint3-analytics-cristina.sprint3_gold.fact_transactions_optimized`
WHERE timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY);


-- EXERCICI 4 Smart Caching (Vistes Materialitzades)

-- Creamos la vista materializada:
CREATE OR REPLACE MATERIALIZED VIEW `sprint3-analytics-cristina.sprint3_gold.mv_daily_sales`
AS (
  SELECT DATE(t.timestamp) AS date, SUM(t.amount) AS sales
  FROM `sprint3-analytics-cristina.sprint3_gold.fact_transactions_optimized` t
  WHERE t.declined = 0
  GROUP BY DATE(t.timestamp)
);

SELECT *
FROM sprint3-analytics-cristina.sprint3_gold.mv_daily_sales
ORDER BY date DESC;


--NIVELL 2
--EXERCICI 1 Perfilat de Clients VIP (Mètriques Agregades amb CTEs)

WITH VIP_Stats AS (
  SELECT t.user_id, ROUND(SUM(t.amount),2) AS total_gasto, COUNT(t.transaction_id) AS total_transacciones, ROUND(AVG(t.amount),2) AS media_gasto, MAX(t.amount) AS maximo_gasto
  FROM sprint3-analytics-cristina.sprint3_gold.fact_transactions_optimized t
  WHERE t.declined = 0
  GROUP BY t.user_id
  HAVING total_gasto > 500) 
SELECT u.user_id, u.name, u.surname,v.total_transacciones, v.media_gasto, v.maximo_gasto, v.total_gasto
FROM VIP_Stats v
JOIN sprint3-analytics-cristina.sprint3_silver.users_combined u
ON v.user_id = u.user_id
ORDER BY total_gasto DESC;


--EXERCICI 2 Anàlisi de Tendències (Window Functions sobre Vistes)

SELECT m.date, ROUND(sales,2) AS Vendes_Avui, ROUND(LAG(sales) OVER (ORDER BY date),2) AS Vendes_ahir, 
  ROUND(SAFE_DIVIDE (sales - LAG(sales) OVER (ORDER BY date), LAG(sales) OVER (ORDER BY date))  *100,2) AS Diff_Percentual
FROM sprint3-analytics-cristina.sprint3_gold.mv_daily_sales m
ORDER BY m.date;


--EXERCICI 3 Totals Acumulats (Running Totals sobre Vistes)

SELECT m.date, EXTRACT(YEAR FROM m.date) AS year, ROUND(sales,2) AS Vendes_Avui, ROUND(CAST(SUM(sales) OVER (PARTITION BY EXTRACT(YEAR FROM date) ORDER BY date
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS NUMERIC),2)  AS Vendes_Acumulades_YTD
FROM  sprint3-analytics-cristina.sprint3_gold.mv_daily_sales m
ORDER BY m.date DESC;  


--EXERCICI 4 Fidelització i Valor del Client (Filtratge Avançat)

WITH VIP_Clients AS (
  SELECT  ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY t.timestamp) AS rn, t.user_id, t.transaction_id, DATE(t.timestamp) AS date, t.amount 
FROM sprint3-analytics-cristina.sprint3_gold.fact_transactions_optimized t
WHERE declined = 0
QUALIFY rn <= 3)
SELECT u.user_id, u.name, u.surname, u.email, MAX(IF(v.rn = 3, v.date, NULL)) AS date_3a_compra, MAX(IF(v.rn = 3, v.amount, NULL)) AS importe_3a_compra, ROUND(AVG(v.amount), 2) AS media_3_primeras
FROM VIP_Clients v
JOIN sprint3-analytics-cristina.sprint3_silver.users_combined u
ON v.user_id = u.user_id
GROUP BY u.user_id, u.name, u.surname, u.email
HAVING COUNT(*) = 3;


--NIVELL 3

--EXERCICI 1 Desanidament i Aplanament de Dades (Unnesting)

-- Creamos la tabla:

CREATE OR REPLACE TABLE sprint3-analytics-cristina.sprint3_gold.dim_transactions_flat AS(
SELECT t.transaction_id, DATE(t.timestamp) AS timestamp,t.amount AS total_ticket,product_id AS product_sku,p.name AS product_name,p.price AS product_price
FROM sprint3-analytics-cristina.sprint3_gold.fact_transactions_optimized t
  CROSS JOIN UNNEST(t.product_ids) AS product_id
JOIN sprint3-analytics-cristina.sprint3_silver.products_clean p
ON product_id = p.product_id 
WHERE t.declined = 0);



--EXERCICI 2 El Rànquing de Vendes (Agregació Simple)

--Hacemos la consulta para obtener el top 5 de productos más vendidos:

SELECT d.product_sku, d.product_name, COUNT(d.product_sku) AS total_sales_product
FROM sprint3-analytics-cristina.sprint3_gold.dim_transactions_flat d
GROUP BY d.product_sku, d.product_name
ORDER BY total_sales_product DESC
LIMIT 5;


--EXERCICI 3 

--Creamos la UDF para calcular IVA:
CREATE OR REPLACE FUNCTION `sprint3-analytics-cristina.sprint3_gold.calculate_tax`(
  amount FLOAT64
) AS (
  ROUND(amount * 0.21, 2)
);



-- Actualizamos la tabla:
CREATE OR REPLACE TABLE sprint3-analytics-cristina.sprint3_gold.dim_transactions_flat AS(
SELECT t.transaction_id, DATE(t.timestamp) AS timestamp,t.amount AS total_ticket, product_id AS product_sku,p.name AS product_name,
p.price AS product_price, p.price + `sprint3-analytics-cristina.sprint3_gold.calculate_tax`(p.price) AS  product_price_tax_inc
FROM sprint3-analytics-cristina.sprint3_gold.fact_transactions_optimized t
  CROSS JOIN UNNEST(t.product_ids) AS product_id
JOIN sprint3-analytics-cristina.sprint3_silver.products_clean p
ON product_id = p.product_id 
WHERE t.declined = 0);



--Enlace al looker:

-- https://datastudio.google.com/reporting/37e7cf90-7d8d-435c-9f90-b527ea1a28bc

