-- Interim: order lines joined to their order header, typed, and limited to the
-- loaded date window. One row per order line. Not a mart: fct_order_line shapes it.
--
-- ORDER_CHANNEL, ORDER_TAX_AMOUNT and ORDER_DISCOUNT_AMOUNT are left out: they are
-- NULL throughout the raw data.

with order_header as (

    select *
    from {{ source('tasty_bytes', 'order_header') }}
    -- var(): project variable from dbt_project.yml, overridable with --vars.
    where order_ts >= '{{ var("tasty_bytes_order_start_date") }}'

),

order_detail as (

    select *
    from {{ source('tasty_bytes', 'order_detail') }}

)

select
    d.order_detail_id,
    d.order_id,
    d.line_number,
    h.order_ts,
    h.order_ts::date            as order_date,
    h.truck_id,
    h.location_id::number(19,0) as location_id,  -- FLOAT in the raw data
    h.customer_id,                               -- NULL for non-loyalty customers
    d.menu_item_id,
    d.quantity,
    d.unit_price,
    d.price                     as line_amount
from order_detail as d
inner join order_header as h
    on d.order_id = h.order_id
