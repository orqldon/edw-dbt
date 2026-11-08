-- Order line fact: one row per order line in the loaded window.
-- Keys to each dimension plus additive measures; descriptive columns live in the dims.
--
-- Incremental: the first build (or --full-refresh) creates the table from the whole
-- window; later builds MERGE in only order lines newer than the newest one already
-- loaded. unique_key makes the merge update a re-sent line instead of duplicating it.
-- Lowering tasty_bytes_order_start_date doesn't backfill: rebuild with --full-refresh.

{{ config(
    materialized='incremental',
    unique_key='order_detail_id',
    incremental_strategy='merge'
) }}

SELECT
    lines.order_detail_id,
    lines.order_id,
    lines.line_number,
    lines.order_ts,
    lines.order_date,
    lines.truck_id,
    lines.location_id,
    COALESCE(lines.customer_id, -1) AS customer_id,  -- -1 = dim_customer's unknown row
    lines.menu_item_id,
    lines.quantity,
    lines.unit_price,
    lines.line_amount
FROM {{ ref('int_order_lines') }} AS lines

{% if is_incremental() %}
    -- is_incremental() is true only when the table already exists and this isn't a
    -- --full-refresh; `this` is the existing table.
    WHERE lines.order_ts > (SELECT MAX(existing.order_ts) FROM {{ this }} AS existing)
{% endif %}
