-- Pass-through presentation view over dim_customer. Consumers read T5 only, so T4
-- can change behind this view without breaking them.

select *
from {{ ref('dim_customer') }}
