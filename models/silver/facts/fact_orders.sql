{{
  config(
    materialized='incremental',
    unique_key='order_id',
    on_schema_change='fail',
    tags=['facts', 'silver']
  )
}}

-- Silver Layer - Fact Orders
-- Transforms raw orders into analytics-ready fact table

WITH source_orders AS (
    SELECT * FROM {{ source('bronze', 'raw_orders') }}
    
    {% if is_incremental() %}
    -- Incremental logic: only process new/updated records
    WHERE load_timestamp > (SELECT MAX(created_at) FROM {{ this }})
    {% endif %}
),

cleaned_orders AS (
    SELECT
        -- Natural key
        order_id,
        
        -- Dimension keys (to be looked up from dimension tables)
        customer_id,
        product_id,
        
        -- Dates
        order_date,
        ship_date,
        delivery_date,
        
        -- Degenerate dimensions (attributes not in dimension tables)
        ship_mode,
        order_priority,
        order_status,
        
        -- Measures
        order_quantity,
        unit_price,
        discount,
        sales,
        profit,
        
        -- Derived metrics
        CASE 
            WHEN delivery_date <= ship_date + INTERVAL '3 days' THEN TRUE 
            ELSE FALSE 
        END AS is_fast_shipping,
        
        DATEDIFF(day, order_date, delivery_date) AS days_to_deliver,
        
        sales - profit AS cost,
        
        CASE 
            WHEN profit < 0 THEN 'Loss'
            WHEN profit = 0 THEN 'Break-even'
            ELSE 'Profit'
        END AS profitability_flag,
        
        -- Audit
        load_timestamp AS created_at
        
    FROM source_orders
    WHERE order_id IS NOT NULL
      AND sales IS NOT NULL
      AND order_quantity > 0
),

final AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['order_id']) }} AS order_fact_id,
        *
    FROM cleaned_orders
)

SELECT * FROM final
