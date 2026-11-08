-- Customer dimension: loyalty members, plus one "unknown" row (customer_id = -1)
-- for orders placed without a loyalty account. fct_order_line maps NULL customer
-- ids to -1, so every fact row joins to a customer with an inner join.

SELECT
    customer_id,
    first_name,
    last_name,
    city,
    country,
    gender,
    marital_status,
    sign_up_date,
    false AS is_unknown
FROM {{ source('tasty_bytes', 'customer_loyalty') }}

UNION ALL

SELECT
    -1 AS customer_id,
    -- noqa: RF04 below: the linter's Snowflake dialect lists FIRST_NAME and LAST_NAME
    -- as keywords, but here they are the source's real column names.
    'Unknown' AS first_name,  -- noqa: RF04
    'Unknown' AS last_name,  -- noqa: RF04
    null AS city,
    null AS country,
    null AS gender,
    null AS marital_status,
    null AS sign_up_date,
    true AS is_unknown
