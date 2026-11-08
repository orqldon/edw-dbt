-- Location dimension. The raw table needs no interim processing, so it is read
-- straight from the source; add a T3 model only when there is real work to do.

select
    location_id,
    location        as location_name,
    city,
    region,
    country,
    iso_country_code
from {{ source('tasty_bytes', 'location') }}
