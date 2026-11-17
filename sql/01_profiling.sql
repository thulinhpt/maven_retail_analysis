-- Check if the dataset is fully uploaded
SELECT 'sales' AS tbl, COUNT(*) AS row_count FROM maven_toys.raw_sales
UNION ALL SELECT 'products', COUNT(*) FROM maven_toys.raw_products
UNION ALL SELECT 'stores', COUNT(*) FROM maven_toys.raw_stores
UNION ALL SELECT 'inventory', COUNT(*) FROM maven_toys.raw_inventory
---sales	829262; products	35; stores	50; inventory	1593

-- Sales date range, active stores and products
SELECT
  MIN(Date) AS first_date,
  MAX(Date) AS last_date,
  COUNT(DISTINCT Date) AS days_with_sales,
  COUNT(DISTINCT Store_ID) AS stores_selling,
  COUNT(DISTINCT Product_ID) AS products_sold,
  SUM(Units) AS total_units
FROM maven_toys.raw_sales;
--- Data date from Jan 2022 to Sep 2023
--- stores 50; products 35; units 1m

-- Should all return 0 rows
SELECT Sale_ID,
  COUNT(*) AS n 
FROM maven_toys.raw_sales 
GROUP BY Sale_ID 
HAVING n > 1;
SELECT Product_ID,
 COUNT(*) AS n 
FROM maven_toys.raw_products 
GROUP BY Product_ID 
HAVING n > 1;
SELECT Store_ID,
 COUNT(*) AS n 
FROM maven_toys.raw_stores 
GROUP BY Store_ID 
HAVING n > 1;
SELECT Store_ID, Product_ID,
 COUNT(*) AS n
FROM maven_toys.raw_inventory 
GROUP BY Store_ID, Product_ID 
HAVING n > 1;
--- All id is unique

-- Missing values and odd quantities in sales
SELECT
  COUNTIF(Date IS NULL) AS null_dates,
  COUNTIF(Store_ID IS NULL) AS null_stores,
  COUNTIF(Product_ID IS NULL) AS null_products,
  COUNTIF(Units IS NULL OR Units <= 0) AS bad_units
FROM maven_toys.raw_sales;
--- No null values

-- Sales or stock with no matching product or store
SELECT 'sales_no_product' AS check_name,
 COUNT(*) AS n
FROM maven_toys.raw_sales s 
LEFT JOIN maven_toys.raw_products p 
USING (Product_ID)
WHERE p.Product_ID IS NULL
UNION ALL
SELECT 'sales_no_store',
 COUNT(*)
FROM maven_toys.raw_sales s 
LEFT JOIN maven_toys.raw_stores st 
USING (Store_ID)
WHERE st.Store_ID IS NULL
UNION ALL
SELECT 'inventory_no_product',
 COUNT(*)
FROM maven_toys.raw_inventory i 
LEFT JOIN maven_toys.raw_products p 
USING (Product_ID)
WHERE p.Product_ID IS NULL;
--- No odd data

-- Price and cost format in products
-- Check whether cost and price loaded as text like "$9.99 "
SELECT Product_ID,
  Product_Name,
  Product_Category, 
  Product_Cost, 
  Product_Price
FROM maven_toys.raw_products
LIMIT 10;
--- Cost and Price are in correct format

-- Stock-outs in the inventory snapshot
SELECT
  COUNTIF(Stock_On_Hand = 0) AS zero_stock_rows,
  COUNT(*) AS total_rows,
  ROUND(COUNTIF(Stock_On_Hand = 0) / COUNT(*) * 100, 1) AS pct_out_of_stock
FROM maven_toys.raw_inventory;
--- 4.8%

-- Is the last month complete? (affects monthly and YoY comparisons)
SELECT DATE_TRUNC(Date, MONTH) AS month,
 COUNT(DISTINCT Date) AS days
FROM maven_toys.raw_sales
GROUP BY month
ORDER BY month DESC
LIMIT 3;
--- Last day is EOM

-- Store attributes for slicing (location types and cities)
SELECT Store_Location,
  COUNT(*) AS stores,
  COUNT(DISTINCT Store_City) AS cities,
  COUNT(*)*100/(SUM(COUNT(*)) OVER ()) AS pct_stores
FROM maven_toys.raw_stores
GROUP BY Store_Location
ORDER BY pct_stores DESC;
--- Downtown has 29 stores ~ 58%
--- Commercial has 12 stores ~ 24%
--- Residential has 6 stores ~ 12%
--- Airport has 3 stores ~ 6%

-- Any product priced at or below cost?
SELECT COUNTIF(Product_Price <= Product_Cost) AS bad_margin_products
FROM maven_toys.raw_products;
--- No product price < cost
