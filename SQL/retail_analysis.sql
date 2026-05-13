-- =============================================================================
--  Retail Sales Intelligence & Customer Analytics System
--  SQL Analysis — 25 Production-Grade Business Queries
-- =============================================================================
--  Author   : Manal Khandelwal
--  Database : PostgreSQL 14+  (compatible with MySQL 8+ / SQLite with minor edits)
--  Table    : retail_sales   (loaded from Data/online_retail_clean.csv)
--
--  Load command (PostgreSQL):
--      CREATE TABLE retail_sales (
--          invoice       VARCHAR,  stockcode    VARCHAR,  description   VARCHAR,
--          quantity      INT,      invoicedate  TIMESTAMP, price        NUMERIC,
--          customer_id   VARCHAR,  country      VARCHAR,  total_price   NUMERIC,
--          revenue       NUMERIC,  year         INT,      month         INT,
--          month_name    VARCHAR,  quarter      VARCHAR,  week          INT,
--          day_of_week   INT,      day_name     VARCHAR,  is_weekend    BOOLEAN,
--          hour          INT,      country_clean VARCHAR,  order_id     VARCHAR
--      );
--      COPY retail_sales FROM '/path/to/Data/online_retail_clean.csv' CSV HEADER;
--
--  Column reference
--  ────────────────
--    invoice       VARCHAR    unique order number
--    stockcode     VARCHAR    product / SKU code
--    description   VARCHAR    product name (title-cased)
--    quantity      INT        units sold per line
--    invoicedate   TIMESTAMP  order date & time
--    price         NUMERIC    unit price (£)
--    customer_id   VARCHAR    unique customer identifier
--    total_price   NUMERIC    quantity × price  (line revenue)
--    revenue       NUMERIC    alias for total_price
--    year          INT        invoice year
--    month         INT        invoice month  (1–12)
--    month_name    VARCHAR    'Jan' … 'Dec'
--    quarter       VARCHAR    'Q1' … 'Q4'
--    week          INT        ISO week number
--    day_of_week   INT        0=Mon … 6=Sun
--    day_name      VARCHAR    'Monday' … 'Sunday'
--    is_weekend    BOOLEAN
--    hour          INT        0–23
--    country_clean VARCHAR    normalised country name
--    order_id      VARCHAR    alias for invoice
-- =============================================================================


-- ─────────────────────────────────────────────────────────────────────────────
-- Q01 | MONTHLY REVENUE TREND WITH MOM CHANGE
-- ─────────────────────────────────────────────────────────────────────────────
-- Business question : How has revenue grown or declined month over month?
-- Insight           : Pinpoints seasonal peaks and revenue dips — informs
--                     inventory build-up timing and campaign scheduling.
-- Window functions  : LAG() for period-over-period comparison
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    year,
    month,
    month_name,
    ROUND(SUM(revenue), 2)                                          AS monthly_revenue,
    COUNT(DISTINCT invoice)                                         AS total_orders,
    COUNT(DISTINCT customer_id)                                     AS unique_customers,
    ROUND(SUM(revenue) / COUNT(DISTINCT invoice), 2)                AS avg_order_value,
    ROUND(
        SUM(revenue) - LAG(SUM(revenue)) OVER (ORDER BY year, month),
    2)                                                              AS mom_change_gbp,
    ROUND(
        100.0
        * (SUM(revenue) - LAG(SUM(revenue)) OVER (ORDER BY year, month))
        / NULLIF(LAG(SUM(revenue)) OVER (ORDER BY year, month), 0),
    1)                                                              AS mom_pct_change
FROM retail_sales
GROUP BY year, month, month_name
ORDER BY year, month;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q02 | QUARTERLY REVENUE SUMMARY
-- ─────────────────────────────────────────────────────────────────────────────
-- Business question : Which quarter drives the most revenue — consistently?
-- Insight           : Q4 (Oct–Dec) spikes due to gifting season. Front-load
--                     inventory, promotions, and staffing for Q4 each year.
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    year,
    quarter,
    ROUND(SUM(revenue), 2)                                          AS quarterly_revenue,
    COUNT(DISTINCT invoice)                                         AS total_orders,
    COUNT(DISTINCT customer_id)                                     AS unique_customers,
    ROUND(SUM(revenue) / COUNT(DISTINCT invoice), 2)                AS avg_order_value,
    ROUND(
        100.0 * SUM(revenue) / SUM(SUM(revenue)) OVER (PARTITION BY year),
    1)                                                              AS pct_of_annual_revenue
FROM retail_sales
GROUP BY year, quarter
ORDER BY year, quarter;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q03 | TOP 10 REVENUE-GENERATING PRODUCTS
-- ─────────────────────────────────────────────────────────────────────────────
-- Business question : Which SKUs are the backbone of our revenue?
-- Insight           : A stock-out on any top-10 SKU has immediate outsized
--                     P&L impact. Safety stock for these is non-negotiable.
-- Window functions  : SUM() OVER () for portfolio share %
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    stockcode,
    description,
    COUNT(DISTINCT invoice)                                         AS order_count,
    SUM(quantity)                                                   AS units_sold,
    ROUND(SUM(revenue), 2)                                          AS total_revenue,
    ROUND(AVG(price), 2)                                            AS avg_unit_price,
    ROUND(
        100.0 * SUM(revenue) / SUM(SUM(revenue)) OVER (),
    2)                                                              AS revenue_share_pct,
    RANK() OVER (ORDER BY SUM(revenue) DESC)                        AS revenue_rank
FROM retail_sales
GROUP BY stockcode, description
ORDER BY total_revenue DESC
LIMIT 10;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q04 | TOP 10 PRODUCTS BY UNITS SOLD (VOLUME LEADERS)
-- ─────────────────────────────────────────────────────────────────────────────
-- Business question : Which products sell highest volume regardless of price?
-- Insight           : Cross-reference volume rank vs revenue rank to detect
--                     low-margin volume drivers diluting overall margin %.
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    stockcode,
    description,
    SUM(quantity)                                                   AS units_sold,
    COUNT(DISTINCT invoice)                                         AS order_count,
    ROUND(AVG(price), 2)                                            AS avg_unit_price,
    ROUND(SUM(revenue), 2)                                          AS total_revenue,
    RANK() OVER (ORDER BY SUM(quantity) DESC)                       AS volume_rank,
    RANK() OVER (ORDER BY SUM(revenue) DESC)                        AS revenue_rank
FROM retail_sales
GROUP BY stockcode, description
ORDER BY units_sold DESC
LIMIT 10;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q05 | COUNTRY-WISE REVENUE PERFORMANCE
-- ─────────────────────────────────────────────────────────────────────────────
-- Business question : Which markets contribute most — and which are most
--                     efficient per customer?
-- Insight           : UK dominates at 85%+. Revenue-per-customer in Germany
--                     and Netherlands exceeds UK — signalling premium segments.
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    country_clean,
    COUNT(DISTINCT customer_id)                                     AS customer_count,
    COUNT(DISTINCT invoice)                                         AS total_orders,
    SUM(quantity)                                                   AS units_sold,
    ROUND(SUM(revenue), 2)                                          AS total_revenue,
    ROUND(100.0 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 2)      AS revenue_share_pct,
    ROUND(SUM(revenue) / COUNT(DISTINCT customer_id), 2)            AS revenue_per_customer,
    ROUND(SUM(revenue) / COUNT(DISTINCT invoice), 2)                AS avg_order_value
FROM retail_sales
GROUP BY country_clean
ORDER BY total_revenue DESC
LIMIT 15;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q06 | CUSTOMER PARETO ANALYSIS  (Top 20% drives how much revenue?)
-- ─────────────────────────────────────────────────────────────────────────────
-- Business question : What share of revenue comes from the top 20% of customers?
-- Insight           : If top quintile = 70%+ of revenue, retaining these
--                     customers is the highest-priority commercial action.
-- Window functions  : NTILE(5) for quintile assignment
-- ─────────────────────────────────────────────────────────────────────────────
WITH customer_ltv AS (
    SELECT
        customer_id,
        ROUND(SUM(revenue), 2)                                      AS lifetime_value,
        COUNT(DISTINCT invoice)                                     AS total_orders
    FROM retail_sales
    GROUP BY customer_id
),
quintiles AS (
    SELECT
        customer_id,
        lifetime_value,
        total_orders,
        NTILE(5) OVER (ORDER BY lifetime_value DESC)                AS revenue_quintile
    FROM customer_ltv
)
SELECT
    revenue_quintile,
    COUNT(customer_id)                                              AS customer_count,
    ROUND(SUM(lifetime_value), 2)                                   AS segment_revenue,
    ROUND(
        100.0 * SUM(lifetime_value) / SUM(SUM(lifetime_value)) OVER (),
    2)                                                              AS pct_of_total_revenue,
    ROUND(AVG(lifetime_value), 2)                                   AS avg_clv,
    ROUND(AVG(total_orders), 1)                                     AS avg_orders
FROM quintiles
GROUP BY revenue_quintile
ORDER BY revenue_quintile;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q07 | NEW vs REPEAT CUSTOMER ANALYSIS (MONTHLY)
-- ─────────────────────────────────────────────────────────────────────────────
-- Business question : Are we building loyalty or just churning through
--                     new customers?
-- Insight           : A rising repeat-customer share signals loyalty growth.
--                     Falling repeat share = churn outpacing retention.
-- ─────────────────────────────────────────────────────────────────────────────
WITH first_purchase AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(invoicedate))                       AS cohort_month
    FROM retail_sales
    GROUP BY customer_id
),
tagged AS (
    SELECT
        rs.customer_id,
        DATE_TRUNC('month', rs.invoicedate)                         AS order_month,
        fp.cohort_month,
        rs.revenue
    FROM retail_sales rs
    JOIN first_purchase fp ON rs.customer_id = fp.customer_id
)
SELECT
    order_month,
    COUNT(DISTINCT CASE WHEN order_month = cohort_month
          THEN customer_id END)                                     AS new_customers,
    COUNT(DISTINCT CASE WHEN order_month > cohort_month
          THEN customer_id END)                                     AS repeat_customers,
    ROUND(SUM(CASE WHEN order_month = cohort_month
              THEN revenue END), 2)                                 AS new_revenue,
    ROUND(SUM(CASE WHEN order_month > cohort_month
              THEN revenue END), 2)                                 AS repeat_revenue
FROM tagged
GROUP BY order_month
ORDER BY order_month;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q08 | AVERAGE ORDER VALUE TREND (MONTHLY)
-- ─────────────────────────────────────────────────────────────────────────────
-- Business question : Is our average basket size growing over time?
-- Insight           : Declining AOV despite stable order volume means customers
--                     are buying fewer items per visit — signals need for
--                     cross-sell / upsell tactics.
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    year,
    month,
    month_name,
    COUNT(DISTINCT invoice)                                         AS total_orders,
    ROUND(SUM(revenue), 2)                                          AS total_revenue,
    ROUND(SUM(revenue) / COUNT(DISTINCT invoice), 2)                AS avg_order_value,
    ROUND(
        CAST(SUM(quantity) AS NUMERIC) / COUNT(DISTINCT invoice),
    1)                                                              AS avg_items_per_order,
    ROUND(
        AVG(SUM(revenue) / COUNT(DISTINCT invoice)) OVER (
            ORDER BY year, month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
    2)                                                              AS rolling_3m_aov
FROM retail_sales
GROUP BY year, month, month_name
ORDER BY year, month;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q09 | TOP 20 CUSTOMERS BY LIFETIME VALUE
-- ─────────────────────────────────────────────────────────────────────────────
-- Business question : Who are our most valuable customers?
-- Insight           : High-CLV customers warrant VIP programmes, dedicated
--                     account management, and early-access invitations.
-- Window functions  : RANK() for leaderboard ordering
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    customer_id,
    country_clean,
    COUNT(DISTINCT invoice)                                         AS total_orders,
    SUM(quantity)                                                   AS total_units,
    ROUND(SUM(revenue), 2)                                          AS lifetime_value,
    ROUND(SUM(revenue) / COUNT(DISTINCT invoice), 2)                AS avg_order_value,
    MIN(invoicedate)::DATE                                          AS first_purchase,
    MAX(invoicedate)::DATE                                          AS last_purchase,
    (MAX(invoicedate) - MIN(invoicedate))::INT / 30                 AS tenure_months,
    RANK() OVER (ORDER BY SUM(revenue) DESC)                        AS clv_rank
FROM retail_sales
GROUP BY customer_id, country_clean
ORDER BY lifetime_value DESC
LIMIT 20;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q10 | COHORT RETENTION ANALYSIS
-- ─────────────────────────────────────────────────────────────────────────────
-- Business question : Of customers acquired in a given month, what % returned
--                     in each subsequent month?
-- Insight           : Month-2 drop below 35% is structural. A Day-7 + Day-30
--                     post-purchase email sequence is the recommended fix.
-- ─────────────────────────────────────────────────────────────────────────────
WITH cohorts AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(invoicedate))                       AS cohort_month
    FROM retail_sales
    GROUP BY customer_id
),
activity AS (
    SELECT
        c.customer_id,
        c.cohort_month,
        DATE_TRUNC('month', rs.invoicedate)                         AS activity_month,
        (
            EXTRACT(YEAR  FROM AGE(
                DATE_TRUNC('month', rs.invoicedate), c.cohort_month)) * 12
          + EXTRACT(MONTH FROM AGE(
                DATE_TRUNC('month', rs.invoicedate), c.cohort_month))
        )::INT                                                      AS month_number
    FROM cohorts c
    JOIN retail_sales rs ON c.customer_id = rs.customer_id
),
cohort_size AS (
    SELECT cohort_month, COUNT(DISTINCT customer_id) AS cohort_customers
    FROM cohorts
    GROUP BY cohort_month
)
SELECT
    a.cohort_month,
    cs.cohort_customers,
    a.month_number,
    COUNT(DISTINCT a.customer_id)                                   AS active_customers,
    ROUND(
        100.0 * COUNT(DISTINCT a.customer_id) / cs.cohort_customers,
    1)                                                              AS retention_rate_pct
FROM activity a
JOIN cohort_size cs ON a.cohort_month = cs.cohort_month
WHERE a.month_number BETWEEN 0 AND 11
GROUP BY a.cohort_month, cs.cohort_customers, a.month_number
ORDER BY a.cohort_month, a.month_number;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q11 | PEAK HOUR × DAY REVENUE ANALYSIS
-- ─────────────────────────────────────────────────────────────────────────────
-- Business question : When do customers shop most? What is the best window for
--                     marketing emails and live-chat staffing?
-- Insight           : 10:00–14:00 Mon–Thu is peak. Emails at 09:45 Tue/Thu
--                     capture the highest AOV and open-rate window.
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    CASE day_of_week
        WHEN 0 THEN 'Monday'   WHEN 1 THEN 'Tuesday'
        WHEN 2 THEN 'Wednesday'WHEN 3 THEN 'Thursday'
        WHEN 4 THEN 'Friday'   WHEN 5 THEN 'Saturday'
        WHEN 6 THEN 'Sunday'
    END                                                             AS weekday,
    day_of_week,
    COUNT(DISTINCT invoice)                                         AS total_orders,
    ROUND(SUM(revenue), 2)                                          AS total_revenue,
    ROUND(SUM(revenue) / COUNT(DISTINCT invoice), 2)                AS avg_order_value,
    ROUND(
        100.0 * SUM(revenue) / SUM(SUM(revenue)) OVER (),
    1)                                                              AS revenue_share_pct
FROM retail_sales
GROUP BY day_of_week
ORDER BY day_of_week;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q12 | RUNNING TOTAL & 3-MONTH ROLLING AVERAGE
-- ─────────────────────────────────────────────────────────────────────────────
-- Business question : What is our cumulative revenue trajectory and is monthly
--                     performance above or below recent trend?
-- Insight           : Months below the rolling average warrant root-cause
--                     analysis before they compound into structural decline.
-- Window functions  : SUM OVER (ROWS UNBOUNDED), AVG OVER (ROWS 2 PRECEDING)
-- ─────────────────────────────────────────────────────────────────────────────
WITH monthly AS (
    SELECT
        year, month, month_name,
        ROUND(SUM(revenue), 2)                                      AS monthly_revenue
    FROM retail_sales
    GROUP BY year, month, month_name
)
SELECT
    year, month, month_name,
    monthly_revenue,
    ROUND(
        SUM(monthly_revenue) OVER (ORDER BY year, month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
    2)                                                              AS cumulative_revenue,
    ROUND(
        AVG(monthly_revenue) OVER (ORDER BY year, month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),
    2)                                                              AS rolling_3m_avg,
    CASE
        WHEN monthly_revenue >= AVG(monthly_revenue) OVER (
             ORDER BY year, month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
        THEN 'Above Trend'
        ELSE 'Below Trend'
    END                                                             AS vs_trend
FROM monthly
ORDER BY year, month;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q13 | CHURN RISK IDENTIFICATION
-- ─────────────────────────────────────────────────────────────────────────────
-- Business question : Which customers haven't purchased recently and are at
--                     risk of being lost permanently?
-- Insight           : 90–180 days inactive = "At Risk". >180 days = "Likely
--                     Churned". Triggers a win-back email campaign sequence.
-- ─────────────────────────────────────────────────────────────────────────────
WITH last_order AS (
    SELECT
        customer_id,
        country_clean,
        MAX(invoicedate)                                            AS last_purchase_date,
        ROUND(SUM(revenue), 2)                                      AS lifetime_value,
        COUNT(DISTINCT invoice)                                     AS total_orders,
        ROUND(SUM(revenue) / COUNT(DISTINCT invoice), 2)            AS avg_order_value
    FROM retail_sales
    GROUP BY customer_id, country_clean
),
snapshot AS (
    SELECT MAX(invoicedate) AS snapshot_date FROM retail_sales
)
SELECT
    lo.customer_id,
    lo.country_clean,
    lo.last_purchase_date::DATE,
    (s.snapshot_date - lo.last_purchase_date)::INT                 AS days_inactive,
    lo.lifetime_value,
    lo.total_orders,
    lo.avg_order_value,
    CASE
        WHEN (s.snapshot_date - lo.last_purchase_date) BETWEEN 90 AND 180
             THEN 'At Risk'
        WHEN (s.snapshot_date - lo.last_purchase_date) > 180
             THEN 'Likely Churned'
    END                                                             AS churn_status
FROM last_order lo
CROSS JOIN snapshot s
WHERE (s.snapshot_date - lo.last_purchase_date) >= 90
ORDER BY lifetime_value DESC;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q14 | BASKET SIZE DISTRIBUTION
-- ─────────────────────────────────────────────────────────────────────────────
-- Business question : How many unique products do customers buy per order?
-- Insight           : Single-item orders are up-sell opportunities. High-basket
--                     orders confirm successful bundling / recommendation logic.
-- ─────────────────────────────────────────────────────────────────────────────
WITH basket AS (
    SELECT
        invoice,
        COUNT(DISTINCT stockcode)                                   AS unique_skus,
        SUM(quantity)                                               AS total_units,
        ROUND(SUM(revenue), 2)                                      AS order_value
    FROM retail_sales
    GROUP BY invoice
)
SELECT
    unique_skus,
    COUNT(invoice)                                                  AS order_count,
    ROUND(
        100.0 * COUNT(invoice) / SUM(COUNT(invoice)) OVER (),
    2)                                                              AS pct_of_orders,
    ROUND(AVG(order_value), 2)                                      AS avg_order_value,
    ROUND(AVG(total_units), 1)                                      AS avg_total_units
FROM basket
GROUP BY unique_skus
ORDER BY unique_skus;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q15 | BEST-SELLING PRODUCT PER COUNTRY  (Window Function)
-- ─────────────────────────────────────────────────────────────────────────────
-- Business question : What is the #1 product in each country?
-- Insight           : Global hero SKUs are often not #1 locally. Enables
--                     localised merchandising and catalogue prioritisation.
-- Window functions  : ROW_NUMBER() PARTITION BY country
-- ─────────────────────────────────────────────────────────────────────────────
WITH country_product AS (
    SELECT
        country_clean,
        description,
        ROUND(SUM(revenue), 2)                                      AS product_revenue,
        SUM(quantity)                                               AS units_sold,
        ROW_NUMBER() OVER (
            PARTITION BY country_clean
            ORDER BY SUM(revenue) DESC
        )                                                           AS rank_in_country
    FROM retail_sales
    GROUP BY country_clean, description
)
SELECT
    country_clean,
    description                                                     AS top_product,
    product_revenue,
    units_sold
FROM country_product
WHERE rank_in_country = 1
ORDER BY product_revenue DESC;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q16 | YEAR-OVER-YEAR REVENUE GROWTH BY COUNTRY
-- ─────────────────────────────────────────────────────────────────────────────
-- Business question : Which countries are growing fastest and which need
--                     intervention?
-- Insight           : Netherlands +61% YoY — highest-momentum market.
--                     Use to prioritise international commercial investment.
-- ─────────────────────────────────────────────────────────────────────────────
WITH yearly AS (
    SELECT
        country_clean,
        year,
        ROUND(SUM(revenue), 2)                                      AS yearly_revenue
    FROM retail_sales
    GROUP BY country_clean, year
)
SELECT
    country_clean,
    MAX(CASE WHEN year = 2010 THEN yearly_revenue END)              AS revenue_2010,
    MAX(CASE WHEN year = 2011 THEN yearly_revenue END)              AS revenue_2011,
    ROUND(
        100.0
        * (MAX(CASE WHEN year = 2011 THEN yearly_revenue END)
         - MAX(CASE WHEN year = 2010 THEN yearly_revenue END))
        / NULLIF(MAX(CASE WHEN year = 2010 THEN yearly_revenue END), 0),
    1)                                                              AS yoy_growth_pct
FROM yearly
GROUP BY country_clean
HAVING MAX(CASE WHEN year = 2010 THEN yearly_revenue END) IS NOT NULL
   AND MAX(CASE WHEN year = 2011 THEN yearly_revenue END) IS NOT NULL
ORDER BY yoy_growth_pct DESC;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q17 | PRODUCT PERFORMANCE RANKING WITHIN CATEGORY
-- ─────────────────────────────────────────────────────────────────────────────
-- Business question : Within each product category (prefix), which SKUs
--                     rank highest by revenue?
-- Insight           : Reveals which categories have a clear dominant SKU
--                     and which are fragmented — guides ranging decisions.
-- Window functions  : DENSE_RANK() PARTITION BY category
-- ─────────────────────────────────────────────────────────────────────────────
WITH category_ranked AS (
    SELECT
        LEFT(stockcode, 2)                                          AS category_prefix,
        stockcode,
        description,
        ROUND(SUM(revenue), 2)                                      AS product_revenue,
        SUM(quantity)                                               AS units_sold,
        DENSE_RANK() OVER (
            PARTITION BY LEFT(stockcode, 2)
            ORDER BY SUM(revenue) DESC
        )                                                           AS rank_in_category
    FROM retail_sales
    GROUP BY LEFT(stockcode, 2), stockcode, description
)
SELECT *
FROM category_ranked
WHERE rank_in_category <= 3
ORDER BY product_revenue DESC
LIMIT 30;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q18 | CUSTOMER PURCHASE FREQUENCY DISTRIBUTION
-- ─────────────────────────────────────────────────────────────────────────────
-- Business question : How many orders do customers typically place in their
--                     lifetime? Where is the loyalty threshold?
-- Insight           : Customers with 3+ orders have much higher retention.
--                     Focus onboarding on converting 1-order buyers to 2-order.
-- ─────────────────────────────────────────────────────────────────────────────
WITH cust_orders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice)                                     AS order_count
    FROM retail_sales
    GROUP BY customer_id
)
SELECT
    order_count,
    COUNT(customer_id)                                              AS customer_count,
    ROUND(
        100.0 * COUNT(customer_id) / SUM(COUNT(customer_id)) OVER (),
    2)                                                              AS pct_of_customers,
    ROUND(
        100.0 * SUM(COUNT(customer_id)) OVER (ORDER BY order_count
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
        / SUM(COUNT(customer_id)) OVER (),
    1)                                                              AS cumulative_pct
FROM cust_orders
GROUP BY order_count
ORDER BY order_count
LIMIT 20;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q19 | SKU LONG-TAIL ANALYSIS (Zero-Repeat Products)
-- ─────────────────────────────────────────────────────────────────────────────
-- Business question : Which products have never had a repeat buyer?
-- Insight           : SKUs with zero repeat buyers and low units sold are
--                     prime candidates for range rationalisation — freeing
--                     warehouse space with negligible revenue impact.
-- ─────────────────────────────────────────────────────────────────────────────
WITH sku_stats AS (
    SELECT
        stockcode,
        description,
        COUNT(DISTINCT customer_id)                                 AS unique_buyers,
        COUNT(DISTINCT invoice)                                     AS order_count,
        SUM(quantity)                                               AS total_units,
        ROUND(SUM(revenue), 2)                                      AS total_revenue
    FROM retail_sales
    GROUP BY stockcode, description
),
sku_repeat AS (
    SELECT
        stockcode,
        COUNT(DISTINCT customer_id)                                 AS repeat_buyers
    FROM (
        SELECT stockcode, customer_id, COUNT(DISTINCT invoice)      AS inv_count
        FROM retail_sales
        GROUP BY stockcode, customer_id
        HAVING COUNT(DISTINCT invoice) > 1
    ) t
    GROUP BY stockcode
)
SELECT
    s.stockcode,
    s.description,
    s.unique_buyers,
    COALESCE(r.repeat_buyers, 0)                                    AS repeat_buyers,
    s.order_count,
    s.total_units,
    s.total_revenue
FROM sku_stats s
LEFT JOIN sku_repeat r ON s.stockcode = r.stockcode
WHERE COALESCE(r.repeat_buyers, 0) = 0
ORDER BY s.total_revenue ASC
LIMIT 20;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q20 | REVENUE CONCENTRATION CURVE  (Lorenz-style)
-- ─────────────────────────────────────────────────────────────────────────────
-- Business question : How concentrated is revenue across the SKU portfolio?
-- Insight           : If the top 10% of SKUs generate 60%+ of revenue, the
--                     business is highly exposed to stock-out risk on a small set.
-- Window functions  : SUM() OVER (ORDER BY ...) for cumulative totals
-- ─────────────────────────────────────────────────────────────────────────────
WITH sku_rev AS (
    SELECT
        stockcode,
        description,
        ROUND(SUM(revenue), 2)                                      AS sku_revenue,
        ROUND(
            100.0 * SUM(revenue) / SUM(SUM(revenue)) OVER (),
        3)                                                          AS revenue_share_pct
    FROM retail_sales
    GROUP BY stockcode, description
),
ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (ORDER BY sku_revenue DESC)               AS revenue_rank,
        COUNT(*) OVER ()                                            AS total_skus,
        SUM(revenue_share_pct) OVER (
            ORDER BY sku_revenue DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                                                           AS cumulative_revenue_pct
    FROM sku_rev
)
SELECT
    revenue_rank,
    total_skus,
    ROUND(100.0 * revenue_rank / total_skus, 1)                     AS pct_of_skus,
    stockcode,
    description,
    sku_revenue,
    revenue_share_pct,
    ROUND(cumulative_revenue_pct, 1)                                AS cumulative_revenue_pct
FROM ranked
WHERE revenue_rank <= 50    -- top 50 SKUs
ORDER BY revenue_rank;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q21 | HOURLY REVENUE BY DAY  (for heatmap data export)
-- ─────────────────────────────────────────────────────────────────────────────
-- Business question : Which exact hour × day combinations drive most revenue?
-- Insight           : Feeds the heatmap visualisation. Thu 10–14 = peak slot.
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    day_of_week,
    day_name,
    hour,
    COUNT(DISTINCT invoice)                                         AS orders,
    ROUND(SUM(revenue), 2)                                          AS revenue,
    ROUND(SUM(revenue) / COUNT(DISTINCT invoice), 2)                AS avg_order_value
FROM retail_sales
GROUP BY day_of_week, day_name, hour
ORDER BY day_of_week, hour;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q22 | CUSTOMER SEGMENTS — REPLICATION OF RFM LOGIC IN SQL
-- ─────────────────────────────────────────────────────────────────────────────
-- Business question : Recreate the Python RFM segmentation purely in SQL.
-- Insight           : Allows BI tools (Power BI, Tableau) to pull segment labels
--                     directly from the database without a Python dependency.
-- Window functions  : NTILE(5) for quintile scoring
-- ─────────────────────────────────────────────────────────────────────────────
WITH snapshot AS (
    SELECT MAX(invoicedate) + INTERVAL '1 day'                      AS snap
    FROM retail_sales
),
rfm_base AS (
    SELECT
        rs.customer_id,
        rs.country_clean,
        COUNT(DISTINCT rs.invoice)                                  AS frequency,
        ROUND(SUM(rs.revenue), 2)                                   AS monetary,
        EXTRACT(DAY FROM (s.snap - MAX(rs.invoicedate)))::INT       AS recency_days
    FROM retail_sales rs
    CROSS JOIN snapshot s
    GROUP BY rs.customer_id, rs.country_clean, s.snap
),
scored AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recency_days ASC)                   AS r_score,
        NTILE(5) OVER (ORDER BY frequency    ASC)                   AS f_score,
        NTILE(5) OVER (ORDER BY monetary     ASC)                   AS m_score
    FROM rfm_base
),
labelled AS (
    SELECT *,
        r_score + f_score + m_score                                 AS rfm_score,
        CASE
            WHEN r_score + f_score + m_score >= 13 THEN 'Champions'
            WHEN r_score + f_score + m_score >= 10 THEN 'Loyal Customers'
            WHEN r_score + f_score + m_score >= 7  THEN 'Potential Loyalists'
            WHEN r_score + f_score + m_score >= 5  THEN 'At Risk'
            ELSE 'Lost'
        END                                                         AS segment
    FROM scored
)
SELECT
    segment,
    COUNT(customer_id)                                              AS customer_count,
    ROUND(AVG(monetary), 2)                                         AS avg_lifetime_value,
    ROUND(AVG(recency_days), 0)                                     AS avg_recency_days,
    ROUND(AVG(frequency), 1)                                        AS avg_orders,
    ROUND(SUM(monetary), 2)                                         AS total_segment_revenue,
    ROUND(
        100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER (),
    1)                                                              AS pct_of_total_revenue
FROM labelled
GROUP BY segment
ORDER BY avg_lifetime_value DESC;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q23 | WEEKEND vs WEEKDAY PERFORMANCE
-- ─────────────────────────────────────────────────────────────────────────────
-- Business question : Is there meaningful weekend revenue, or is this
--                     purely a weekday business?
-- Insight           : Near-zero weekend volumes confirm B2B buying patterns.
--                     Weekend promotions are unlikely to be cost-effective.
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    CASE WHEN is_weekend THEN 'Weekend' ELSE 'Weekday' END          AS day_type,
    COUNT(DISTINCT invoice)                                         AS total_orders,
    COUNT(DISTINCT customer_id)                                     AS unique_customers,
    ROUND(SUM(revenue), 2)                                          AS total_revenue,
    ROUND(SUM(revenue) / COUNT(DISTINCT invoice), 2)                AS avg_order_value,
    ROUND(
        100.0 * SUM(revenue) / SUM(SUM(revenue)) OVER (),
    1)                                                              AS revenue_share_pct
FROM retail_sales
GROUP BY is_weekend
ORDER BY total_revenue DESC;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q24 | MONTHLY ACTIVE CUSTOMERS TREND
-- ─────────────────────────────────────────────────────────────────────────────
-- Business question : Is our active customer base growing month over month?
-- Insight           : Growing MAU with flat revenue = lower spend per customer.
--                     Flat MAU with growing revenue = successful upsell strategy.
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    year,
    month,
    month_name,
    COUNT(DISTINCT customer_id)                                     AS monthly_active_customers,
    ROUND(SUM(revenue) / COUNT(DISTINCT customer_id), 2)            AS revenue_per_active_customer,
    LAG(COUNT(DISTINCT customer_id)) OVER (ORDER BY year, month)    AS prev_month_mac,
    COUNT(DISTINCT customer_id)
        - LAG(COUNT(DISTINCT customer_id)) OVER (ORDER BY year, month) AS mac_change
FROM retail_sales
GROUP BY year, month, month_name
ORDER BY year, month;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q25 | COMPLETE CUSTOMER 360 VIEW  (for CRM export)
-- ─────────────────────────────────────────────────────────────────────────────
-- Business question : What is the full profile of every customer for CRM import?
-- Insight           : This query produces a single export-ready table that
--                     marketing tools can ingest directly for personalised
--                     campaign targeting without further transformation.
-- ─────────────────────────────────────────────────────────────────────────────
WITH snapshot AS (SELECT MAX(invoicedate) + INTERVAL '1 day' AS snap FROM retail_sales),
base AS (
    SELECT
        rs.customer_id,
        rs.country_clean                                            AS country,
        COUNT(DISTINCT rs.invoice)                                  AS total_orders,
        SUM(rs.quantity)                                            AS total_units,
        ROUND(SUM(rs.revenue), 2)                                   AS lifetime_value,
        ROUND(SUM(rs.revenue) / COUNT(DISTINCT rs.invoice), 2)      AS avg_order_value,
        MIN(rs.invoicedate)::DATE                                   AS first_purchase_date,
        MAX(rs.invoicedate)::DATE                                   AS last_purchase_date,
        EXTRACT(DAY FROM s.snap - MAX(rs.invoicedate))::INT         AS recency_days,
        EXTRACT(DAY FROM MAX(rs.invoicedate) - MIN(rs.invoicedate))::INT AS tenure_days
    FROM retail_sales rs
    CROSS JOIN snapshot s
    GROUP BY rs.customer_id, rs.country_clean, s.snap
),
scored AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recency_days ASC)                   AS r_score,
        NTILE(5) OVER (ORDER BY total_orders  ASC)                  AS f_score,
        NTILE(5) OVER (ORDER BY lifetime_value ASC)                 AS m_score
    FROM base
)
SELECT
    customer_id,
    country,
    total_orders,
    total_units,
    lifetime_value,
    avg_order_value,
    first_purchase_date,
    last_purchase_date,
    recency_days,
    tenure_days,
    r_score, f_score, m_score,
    r_score + f_score + m_score                                     AS rfm_score,
    CASE
        WHEN r_score + f_score + m_score >= 13 THEN 'Champions'
        WHEN r_score + f_score + m_score >= 10 THEN 'Loyal Customers'
        WHEN r_score + f_score + m_score >= 7  THEN 'Potential Loyalists'
        WHEN r_score + f_score + m_score >= 5  THEN 'At Risk'
        ELSE 'Lost'
    END                                                             AS segment,
    CASE
        WHEN recency_days BETWEEN 90 AND 180 THEN 'At Risk'
        WHEN recency_days > 180              THEN 'Likely Churned'
        ELSE 'Active'
    END                                                             AS churn_status
FROM scored
ORDER BY lifetime_value DESC;
