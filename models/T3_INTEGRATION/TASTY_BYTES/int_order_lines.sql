-- Interim: order lines joined to their order header, typed, and limited to the
-- loaded date window. One row per order line. Not a mart: fct_order_line shapes it.
--
-- ORDER_CHANNEL, ORDER_TAX_AMOUNT and ORDER_DISCOUNT_AMOUNT are left out: they are
-- NULL throughout the raw data.

WITH order_header AS (

    SELECT *
    FROM {{ source('tasty_bytes', 'order_header') }}
    -- var(): project variable from dbt_project.yml, overridable with --vars.
    WHERE order_ts >= '{{ var("tasty_bytes_order_start_date") }}'

),

order_detail AS (

    SELECT *
    FROM {{ source('tasty_bytes', 'order_detail') }}

)

SELECT
    d.order_detail_id,
    d.order_id,
    d.line_number,
    h.order_ts,
    h.order_ts::date AS order_date,
    h.truck_id,
    h.location_id::number(19, 0) AS location_id,  -- FLOAT in the raw data
    h.customer_id,                                -- NULL for non-loyalty customers
    d.menu_item_id,
    d.quantity,
    d.unit_price,
    d.price AS line_amount
FROM order_detail AS d
INNER JOIN order_header AS h
    ON d.order_id = h.order_id
