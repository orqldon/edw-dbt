-- Daily sales per truck, with truck descriptors, for reporting tools.

select
    f.order_date,
    t.truck_id,
    t.truck_brand_name,
    t.primary_city,
    t.country,
    count(distinct f.order_id)  as order_count,
    sum(f.quantity)             as items_sold,
    sum(f.line_amount)          as sales_amount
from {{ ref('fct_order_line') }} as f
inner join {{ ref('dim_truck') }} as t
    on f.truck_id = t.truck_id
group by all
