select route_id, route_start_date, route_end_date
from {{ ref('stg_routes') }}
where route_end_date < route_start_date
