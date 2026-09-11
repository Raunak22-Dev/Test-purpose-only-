{{ config(materialized='table') }}

with staging as (
    select * from {{ ref('stg_orders') }}
),

deduped as (
    select
        customer_email,
        customer_name,
        customer_tier,
        ingested_at,
        row_number() over (
            partition by customer_email 
            order by ingested_at desc
        ) as rn
    from staging
    where customer_email is not null
)

select
    md5(customer_email) as customer_key,
    customer_email,
    customer_name,
    customer_tier
from deduped
where rn = 1