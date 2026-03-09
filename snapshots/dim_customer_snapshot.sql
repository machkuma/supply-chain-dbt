{% snapshot dim_customer_snapshot %}

{{
    config(
      target_schema='core_schema',
      target_database='silver_db',
      unique_key='customer_id',
      strategy='timestamp',
      updated_at='load_timestamp',
      invalidate_hard_deletes=True
    )
}}

-- SCD Type 2 Snapshot for Customer Dimension
-- This automatically tracks changes to customer records over time

SELECT
    customer_id,
    customer_name,
    customer_segment,
    customer_country,
    customer_city,
    customer_state,
    customer_postal_code,
    customer_region,
    load_timestamp
    
FROM {{ source('bronze', 'raw_orders') }}

-- Get distinct customers (deduplicate within same load batch)
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id 
    ORDER BY load_timestamp DESC
) = 1

{% endsnapshot %}
