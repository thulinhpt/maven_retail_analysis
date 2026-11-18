-- =========================================
-- 02_mart.sql : clean dimensions, daily sales fact, stock cover
-- =========================================

-- 1. Products with margin
CREATE OR REPLACE TABLE maven_toys.dim_products AS
SELECT
  Product_ID,
  TRIM(Product_Name)     AS product_name,
  TRIM(Product_Category) AS category,
  Product_Cost           AS unit_cost,
  Product_Price          AS unit_price,
  ROUND((Product_Price - Product_Cost) / Product_Price, 3) AS margin_pct
FROM maven_toys.raw_products;

-- 2. Stores
CREATE OR REPLACE TABLE maven_toys.dim_stores AS
SELECT
  Store_ID,
  TRIM(Store_Name)     AS store_name,
  TRIM(Store_City)     AS city,
  TRIM(Store_Location) AS location_type,
  Store_Open_Date      AS open_date
FROM maven_toys.raw_stores;

-- 3. Daily sales fact (store x product x day)
CREATE OR REPLACE TABLE maven_toys.fct_daily_sales AS
SELECT
  s.Date AS sale_date,
  s.Store_ID,
  s.Product_ID,
  SUM(s.Units)                                AS units,
  SUM(s.Units * p.unit_price)                 AS revenue,
  SUM(s.Units * p.unit_cost)                  AS cost,
  SUM(s.Units * (p.unit_price - p.unit_cost)) AS profit,
  COUNT(*)                                    AS transactions
FROM maven_toys.raw_sales s
JOIN maven_toys.dim_products p USING (Product_ID)
GROUP BY sale_date, s.Store_ID, s.Product_ID;

-- 4. Stock cover and suggested intake
CREATE OR REPLACE TABLE maven_toys.stock_cover AS
WITH last_date AS (
  SELECT MAX(Date) AS max_date FROM maven_toys.raw_sales
),
recent_sales AS (   -- average weekly units over the last 8 weeks
  SELECT s.Store_ID, s.Product_ID, SUM(s.Units) / 8 AS avg_weekly_units
  FROM maven_toys.raw_sales s, last_date
  WHERE s.Date > DATE_SUB(last_date.max_date, INTERVAL 56 DAY)
  GROUP BY s.Store_ID, s.Product_ID
)
SELECT
  i.Store_ID,
  i.Product_ID,
  i.Stock_On_Hand                              AS stock_units,
  i.Stock_On_Hand * p.unit_cost                AS stock_value_at_cost,
  ROUND(COALESCE(r.avg_weekly_units, 0), 1)    AS avg_weekly_units,
  ROUND(SAFE_DIVIDE(i.Stock_On_Hand, r.avg_weekly_units), 1) AS weeks_of_cover,
  CASE
    WHEN i.Stock_On_Hand = 0 AND COALESCE(r.avg_weekly_units, 0) > 0 THEN 'Out of stock'
    WHEN i.Stock_On_Hand = 0 AND COALESCE(r.avg_weekly_units, 0) = 0  THEN 'Not stocked'
    WHEN COALESCE(r.avg_weekly_units, 0) = 0 AND i.Stock_On_Hand > 0  THEN 'No recent sales'
    WHEN SAFE_DIVIDE(i.Stock_On_Hand, r.avg_weekly_units) < 2         THEN 'Low (<2 wks)'
    WHEN SAFE_DIVIDE(i.Stock_On_Hand, r.avg_weekly_units) > 12        THEN 'Overstock (>12 wks)'
    ELSE 'Healthy' -- 2-12 weeks of cover
  END AS stock_status,
  GREATEST(CEIL(4 * COALESCE(r.avg_weekly_units, 0) - i.Stock_On_Hand), 0) AS suggested_intake_units
FROM maven_toys.raw_inventory i
JOIN maven_toys.dim_products p USING (Product_ID)
LEFT JOIN recent_sales r USING (Store_ID, Product_ID);

-- =========================================
-- 5. Checks
-- =========================================

-- Reconciliation: raw vs mart units
SELECT
  (SELECT SUM(Units) FROM maven_toys.raw_sales)       AS raw_units,
  (SELECT SUM(units) FROM maven_toys.fct_daily_sales) AS mart_units;
--- raw_units = mart_units = 1,090,565 (no units lost or duplicated)

-- Stock status summary
SELECT stock_status,
  COUNT(*) AS store_product_rows,
  ROUND(SUM(stock_value_at_cost)) AS stock_value,
  SUM(suggested_intake_units) AS intake_units
FROM maven_toys.stock_cover
GROUP BY stock_status
ORDER BY store_product_rows DESC;
--- Healthy 687 rows ($170,521) · Low 503 ($60,072; 20,688 intake units)
--- No recent sales 186 ($30,052) · Overstock 140 ($39,565) · Out of stock 77 (2,663 intake units)
--- Total 1,593 rows = inventory table; total stock value $300,210
