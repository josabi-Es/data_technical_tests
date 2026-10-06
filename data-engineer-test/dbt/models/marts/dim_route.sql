select
    route_id as route_key,
    campaign_id as campaign_key,
    route_start_date,
    route_end_date,
    route_status
from {{ ref('stg_routes') }}

union all

{# unknown row #}
select
    -1,
    -1,
    null::date,
    null::date,
    'UNKNOWN'
