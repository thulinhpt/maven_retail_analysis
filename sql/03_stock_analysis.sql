-- =========================================
-- 03_stock_analysis.sql : slow stock and store transfer opportunities
-- Source: maven_toys.stock_cover (8-week sales window ending 30 Sep 2023)
-- =========================================

-- 1. Is "No recent sales" concentrated in certain products (possibly discontinued)?
SELECT p.product_name, p.category,
  COUNT(*) AS stores,
  SUM(c.stock_units) AS units,
  ROUND(SUM(c.stock_value_at_cost)) AS value
FROM maven_toys.stock_cover c
JOIN maven_toys.dim_products p USING (Product_ID)
WHERE c.stock_status = 'No recent sales'
GROUP BY 1, 2
ORDER BY value DESC;
--- PlayDoh Playset has the most stock-value with no sales in 8 weeks: $4,765 across 18 stores.
--- Dinosaur Figures ($3,693, 6 stores), Supersoaker Water Gun ($3,681, 25 stores), Toy Robot ($3,023, 9 stores).
--- Note: the latest sales date is 30 Sep 2023, so the 8-week window covers Aug-Sep. Seasonal items (e.g. Supersoaker) may be off-season, not dead stock.
--- Check monthly sales before recommending markdowns.

-- 2. Transfer opportunity: products overstocked in some stores and low/out in others
SELECT p.product_name,
  COUNTIF(c.stock_status IN ('Overstock (>12 wks)', 'No recent sales')) AS stores_with_excess,
  COUNTIF(c.stock_status IN ('Low (<2 wks)', 'Out of stock'))         AS stores_short
FROM maven_toys.stock_cover c
JOIN maven_toys.dim_products p USING (Product_ID)
GROUP BY 1
HAVING stores_with_excess > 0 AND stores_short > 0
ORDER BY stores_short DESC;
--- Short almost everywhere -> increase intake: Barrel O' Slime (37 short / 1 excess),
--- Hot Wheels 5-Pack (34/3), PlayDoh Can (29/1).
--- Excess almost everywhere -> pause reorders / markdown: Supersoaker (28 excess / 4 short), 
--- Teddy Bear (28/7), Plush Pony (24/7).
--- Mixed -> transfer between stores first: Foam Disk Launcher (14/21), 
--- Toy Robot (14/10), Etch A Sketch (10/24).
