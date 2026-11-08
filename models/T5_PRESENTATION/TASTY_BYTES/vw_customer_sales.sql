-- Sales per loyalty customer over the loaded window (the quickstart's
-- customer_loyalty_metrics, rebuilt over the star). Unknown customers are excluded.

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.city,
    c.country,
    COUNT(DISTINCT f.order_id) AS order_count,
    SUM(f.line_amount) AS total_sales,
    ARRAY_SORT(ARRAY_AGG(DISTINCT f.location_id)) AS visited_location_ids
FROM {{ ref('fct_order_line') }} AS f
INNER JOIN {{ ref('dim_customer') }} AS c
    ON f.customer_id = c.customer_id
WHERE NOT c.is_unknown
GROUP BY ALL
