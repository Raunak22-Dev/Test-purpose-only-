{{ config(materialized='incremental',
            unique_key='order_item_id') }}

with staging as (
    select * from {{ ref('stg_orders') }}
    {% if is_incremental() %}
    -- only process records newer than the most recent ordered_at in the destination table
    where ingested_at>(select max(ordered_at) from {{ this }})
    {% endif %}
),

customers as (
    select * from {{ ref('dim_customers') }}
)

select
    -- Primary Key for this Fact table
    s.order_item_id,
    
    -- Foreign Keys connecting to Dimensions
    s.transaction_id,
    c.customer_key,
    s.store_code,
    s.item_sku,
    
    -- Event Context / Attributes
    s.payment_method,
    s.payment_status,
    s.ingested_at as ordered_at,
    
    -- Numeric Metrics (Additive Facts)
    s.quantity,
    s.unit_price,
    s.gross_item_amount
from staging s
left join customers c
    on s.customer_email = c.customer_email