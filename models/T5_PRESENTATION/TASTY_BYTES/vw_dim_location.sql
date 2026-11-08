-- Pass-through presentation view over dim_location. Consumers read T5 only, so T4
-- can change behind this view without breaking them.

SELECT *
FROM {{ ref('dim_location') }}
