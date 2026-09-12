with source as (
    select * from {{ source('snowflake_raw', 'raw_orders') }}
),

flattened as (
    select
        ingested_at,
        raw_payload:transaction_id::string as transaction_id,
        raw_payload:store_code::string as store_code,
        raw_payload:customer.name::string as customer_name,
        raw_payload:customer.email::string as customer_email,
        raw_payload:customer.loyalty_tier::string as customer_tier,
        raw_payload:payment.method::string as payment_method,
        raw_payload:payment.status::string as payment_status,
        f.index as item_index,
        f.value:sku::string as item_sku,
        f.value:price::number(10,2) as unit_price,
        f.value:quantity::number as quantity
    from source,
    lateral flatten(input => raw_payload:items) f
)

select
    -- Surrogate key hashing transaction, SKU, item index, and ingest timestamp
    md5(concat(
        coalesce(transaction_id, 'UNKNOWN_TXN'),
        '-',
        coalesce(item_sku, 'UNKNOWN_SKU'),
        '-',
        item_index::string,
        '-',
        ingested_at::string
    )) as order_item_id,
    transaction_id,
    store_code,
    customer_name,
    customer_email,
    customer_tier,
    payment_method,
    payment_status,
    item_sku,
    quantity,
    unit_price,
    (quantity * unit_price) as gross_item_amount,
    ingested_at
from flattened