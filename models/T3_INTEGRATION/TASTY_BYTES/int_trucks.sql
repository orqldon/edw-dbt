-- Interim: one row per truck, with its brand (from MENU) and franchisee (from FRANCHISE).
-- MENU is at menu-item grain, so it is reduced to one row per menu type before joining.
-- FRANCHISE repeats some franchise_ids (one row per city the franchisee works in), so it
-- is reduced to one row per franchisee too; otherwise those trucks would be duplicated.

WITH truck AS (

    SELECT *
    FROM {{ source('tasty_bytes', 'truck') }}

),

menu_type AS (

    SELECT DISTINCT
        menu_type_id,
        menu_type,
        truck_brand_name
    FROM {{ source('tasty_bytes', 'menu') }}

),

franchise AS (

    SELECT DISTINCT
        franchise_id,
        first_name,
        last_name
    FROM {{ source('tasty_bytes', 'franchise') }}

)

SELECT
    t.truck_id,
    m.truck_brand_name,
    m.menu_type,
    t.primary_city,
    t.region,
    t.country,
    t.make,
    t.model,
    t.year AS model_year,
    t.ev_flag = 1 AS is_electric,
    t.truck_opening_date,
    t.franchise_flag = 1 AS is_franchise,
    t.franchise_id,
    f.first_name || ' ' || f.last_name AS franchisee_name
FROM truck AS t
LEFT JOIN menu_type AS m
    ON t.menu_type_id = m.menu_type_id
LEFT JOIN franchise AS f
    ON t.franchise_id = f.franchise_id
