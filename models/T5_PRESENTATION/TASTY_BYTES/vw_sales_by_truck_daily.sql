-- Daily sales per truck, with truck descriptors, for reporting tools.

SELECT
    f.order_date,
    t.truck_id,
    t.truck_brand_name,
    t.primary_city,
    t.country,
    COUNT(DISTINCT f.order_id) AS order_count,
    SUM(f.quantity) AS items_sold,
    SUM(f.line_amount) AS sales_amount
FROM {{ ref('fct_order_line') }} AS f
INNER JOIN {{ ref('dim_truck') }} AS t
    ON f.truck_id = t.truck_id
GROUP BY ALL
