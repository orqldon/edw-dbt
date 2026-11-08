-- Pass-through presentation view over fct_order_line. Consumers read T5 only, so T4
-- can change behind this view without breaking them.

SELECT *
FROM {{ ref('fct_order_line') }}
