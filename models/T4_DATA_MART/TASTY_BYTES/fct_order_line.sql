-- Order line fact: one row per order line in the loaded window.
-- Keys to each dimension plus additive measures; descriptive columns live in the dims.

select
    order_detail_id,
    order_id,
    line_number,
    order_ts,
    order_date,
    truck_id,
    location_id,
    coalesce(customer_id, -1) as customer_id,  -- -1 = dim_customer's unknown row
    menu_item_id,
    quantity,
    unit_price,
    line_amount
from {{ ref('int_order_lines') }}
