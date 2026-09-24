{{ config(severity='warn') }}

select
    visits.visit_id,
    visits.visit_date,
    routes.route_start_date,
    routes.route_end_date
from {{ ref('stg_visits') }} as visits
join {{ ref('stg_routes') }} as routes
    on visits.route_id = routes.route_id
where visits.visit_date not between routes.route_start_date and routes.route_end_date
