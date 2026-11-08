-- Truck dimension. All shaping happens in int_trucks; the mart layer only
-- decides what is published and persists it as a table.

SELECT *
FROM {{ ref('int_trucks') }}
