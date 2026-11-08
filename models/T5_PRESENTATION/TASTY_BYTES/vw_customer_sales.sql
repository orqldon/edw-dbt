-- Sales per loyalty customer over the loaded window (the quickstart's
-- customer_loyalty_metrics, rebuilt over the star). Unknown customers are excluded.

select
    c.customer_id,
    c.first_name,
    c.last_name,
    c.city,
    c.country,
    count(distinct f.order_id)                        as order_count,
    sum(f.line_amount)                                as total_sales,
    array_sort(array_agg(distinct f.location_id))     as visited_location_ids
from {{ ref('fct_order_line') }} as f
inner join {{ ref('dim_customer') }} as c
    on f.customer_id = c.customer_id
where not c.is_unknown
group by all
