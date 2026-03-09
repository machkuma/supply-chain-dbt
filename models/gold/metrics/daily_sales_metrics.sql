{{
  config(
    materialized='table',
    tags=['gold', 'metrics', 'daily']
  )
}}

-- Gold Layer - Daily Sales Metrics
-- Aggregated metrics for reporting and dashboards

WITH daily_orders AS (
    SELECT
        order_date,
        customer_id,
        product_id,
        
        -- Aggregated metrics
        COUNT(DISTINCT order_id) AS total_orders,
        SUM(order_quantity) AS total_quantity,
        SUM(sales) AS total_sales,
        SUM(profit) AS total_profit,
        AVG(discount) AS avg_discount,
        
        -- Derived metrics
        SUM(profit) / NULLIF(SUM(sales), 0) AS profit_margin,
        AVG(days_to_deliver) AS avg_delivery_days,
        
        -- Flags
        SUM(CASE WHEN is_fast_shipping THEN 1 ELSE 0 END) AS fast_shipping_count,
        SUM(CASE WHEN profitability_flag = 'Profit' THEN 1 ELSE 0 END) AS profitable_orders_count
        
    FROM {{ ref('fact_orders') }}
    GROUP BY order_date, customer_id, product_id
),

with_running_totals AS (
    SELECT
        *,
        
        -- Running totals
        SUM(total_sales) OVER (
            PARTITION BY customer_id 
            ORDER BY order_date 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS customer_lifetime_value,
        
        -- Moving averages (7-day)
        AVG(total_sales) OVER (
            ORDER BY order_date 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS sales_7day_ma
        
    FROM daily_orders
)

SELECT * FROM with_running_totals
