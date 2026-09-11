{{ config(materialized='view') }}

with source_data as (
    select * from {{ source('snowflake_raw', 'raw_orders') }}
),

flattened as (
    select
        raw_payload:transaction_id::string as transaction_id,
        raw_payload:store_code::string as store_code,
        raw_payload:customer.name::string as customer_name,
        raw_payload:customer.email::string as customer_email,
        raw_payload:customer.loyalty_tier::string as customer_tier,
        raw_payload:payment.method::string as payment_method,
        raw_payload:payment.status::string as payment_status,
        item.value:sku::string as item_sku,
        item.value:price::numeric(10,2) as unit_price,
        item.value:quantity::int as quantity,
        ingested_at
    from source_data,
    lateral flatten(input => raw_payload:items) item
)

select 
    md5(concat(coalesce(transaction_id, ''), '-', coalesce(item_sku, ''))) as order_item_id,
    transaction_id,
    store_code,
    customer_name,
    customer_email,
    customer_tier,
    payment_method,
    payment_status,
    item_sku,
    unit_price,
    quantity,
    (unit_price * quantity) as gross_item_amount,
    ingested_at
from flattened