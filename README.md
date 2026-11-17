# Retail Sales & Stock Analysis – Maven Toys (50 stores)

Weekly trading, product performance and stock-cover analysis for a multi-store toy retailer,
built with **BigQuery SQL** and **Tableau**.

**Live dashboard:** [Tableau Public link – coming soon]

## Business questions
1. How are sales and profit trending week by week, by store, city and location type?
2. Which products and categories drive revenue and profit?
3. Where are we at risk of stock-outs or overstock, and how much should each store reorder?

## Dataset
- Source: [Maven Analytics – Mexico Toy Sales](https://mavenanalytics.io/data-playground/mexico-toy-sales) (public, fictional company)
- Period: January 2022 – September 2023 (21 complete months)
- 829,262 sales transactions · 50 stores · 29 cities · 35 products · 1,593 inventory rows

| Table | Description |
|---|---|
| sales | Daily transactions: date, store, product, units |
| products | Product name, category, unit cost, unit price |
| stores | Store name, city, location type, open date |
| inventory | Current stock on hand per store and product (single snapshot) |

## Approach
1. **Data profiling** (`sql/01_profiling.sql`): row counts, date range, duplicates, nulls, orphan keys, pricing checks.
2. **Data mart** (`sql/02_mart.sql`): clean dimension tables, a weekly sales fact table (store × product × week)
   and a stock-cover table with suggested intake.
3. **Reconciliation:** mart totals checked against raw sales.
4. **Dashboards** in Tableau: Weekly trading · Product & category · Stock & intake.
5. - **Stock status:** Out of stock (0 units, still selling) · Low (< 2 weeks) · Overstock (> 12 weeks) · No recent sales (stock but no sales in 8 weeks) · Healthy

## Data quality notes
- No duplicate IDs, null values, invalid units or orphan keys were found.
- September 2023 is complete, so all 21 months can be compared.
- Stores by location type: Downtown 29 (58%), Commercial 12 (24%), Residential 6 (12%), Airport 3 (6%).
- 4.8% of store-product combinations had zero stock in the inventory snapshot.
- Inventory has no date; it is treated as the stock position at the end of the period.

## Business rules (assumptions)
- **Average weekly sales** = units sold in the last 8 weeks ÷ 8
- **Weeks of cover** = stock on hand ÷ average weekly sales
- **Stock status:** Out of stock (0 units, still selling) · Low (< 2 weeks) · Overstock (> 12 weeks) · Healthy
- **Suggested intake** = units needed to reach 4 weeks of cover

These thresholds are assumptions and would be agreed with a planning team in practice.

## Key insights
- [Insight 1 – e.g. top category by profit and its share]
- [Insight 2 – e.g. best and worst location type]
- [Insight 3 – e.g. stock value tied up in overstock, and stores at stock-out risk]

## Recommendations
- [1–3 actions based on the insights]

## Repository structure
```
sql/
  01_profiling.sql
  02_mart.sql
images/
  dashboard screenshots
README.md
```

## Tools
BigQuery (SQL) · Tableau Public · GitHub

---
*Thu Linh Pham · [LinkedIn](https://www.linkedin.com/in/thu-linh-pham/)*
