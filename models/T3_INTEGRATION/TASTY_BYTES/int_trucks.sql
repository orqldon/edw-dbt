-- Interim: one row per truck, with its brand (from MENU) and franchisee (from FRANCHISE).
-- MENU is at menu-item grain, so it is reduced to one row per menu type before joining.
-- FRANCHISE repeats some franchise_ids (one row per city the franchisee works in), so it
-- is reduced to one row per franchisee too; otherwise those trucks would be duplicated.

with truck as (

    select *
    from {{ source('tasty_bytes', 'truck') }}

),

menu_type as (

    select distinct
        menu_type_id,
        menu_type,
        truck_brand_name
    from {{ source('tasty_bytes', 'menu') }}

),

franchise as (

    select distinct
        franchise_id,
        first_name,
        last_name
    from {{ source('tasty_bytes', 'franchise') }}

)

select
    t.truck_id,
    m.truck_brand_name,
    m.menu_type,
    t.primary_city,
    t.region,
    t.country,
    t.make,
    t.model,
    t.year                              as model_year,
    t.ev_flag = 1                       as is_electric,
    t.truck_opening_date,
    t.franchise_flag = 1                as is_franchise,
    t.franchise_id,
    f.first_name || ' ' || f.last_name  as franchisee_name
from truck as t
left join menu_type as m
    on t.menu_type_id = m.menu_type_id
left join franchise as f
    on t.franchise_id = f.franchise_id
