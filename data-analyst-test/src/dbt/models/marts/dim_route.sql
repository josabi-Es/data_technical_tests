select
    route_id,
    route_code,
    campaign_id,
    route_name,
    route_start_date,
    route_end_date,
    route_status,
    delegation_code
from {{ ref('stg_routes') }}

union all

-- row for visits without route
select
    -1 as route_id,
    cast(null as varchar) as route_code,
    cast(null as integer) as campaign_id,
    'No route' as route_name,
    cast(null as date) as route_start_date,
    cast(null as date) as route_end_date,
    'UNKNOWN' as route_status,
    cast(null as varchar) as delegation_code
