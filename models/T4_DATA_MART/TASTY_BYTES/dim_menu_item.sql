-- Menu item dimension: one row per item sold.

select
    menu_item_id,
    menu_item_name,
    item_category,
    item_subcategory,
    menu_type,
    truck_brand_name,
    cost_of_goods_usd,
    sale_price_usd
from {{ source('tasty_bytes', 'menu') }}
