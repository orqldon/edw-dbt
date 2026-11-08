-- Customer dimension: loyalty members, plus one "unknown" row (customer_id = -1)
-- for orders placed without a loyalty account. fct_order_line maps NULL customer
-- ids to -1, so every fact row joins to a customer with an inner join.

select
    customer_id,
    first_name,
    last_name,
    city,
    country,
    gender,
    marital_status,
    sign_up_date,
    false as is_unknown
from {{ source('tasty_bytes', 'customer_loyalty') }}

union all

select
    -1,
    'Unknown',
    'Unknown',
    null,
    null,
    null,
    null,
    null,
    true
