{% snapshot snap_customers %}

{{
    config(
      target_database='dev_warehouse',
      target_schema='staging',
      unique_key='customer_email',
      strategy='check',
      check_cols=['customer_name', 'customer_tier'],
      invalidate_hard_deletes=True
    )
}}

select
    customer_email,
    customer_name,
    customer_tier
from {{ ref('dim_customers') }}

{% endsnapshot %}