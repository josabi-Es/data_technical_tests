with main_worker as (

    select
        route_id,
        employee_id
    from {{ ref('stg_route_employee') }}
    where main_employee

)

select
    v.visit_id,
    v.campaign_id,
    v.intervention_point_id,
    -- no route or orphan route
    coalesce(r.route_id, -1) as route_id,
    mw.employee_id,
    v.visit_date,
    v.visit_time,
    v.visit_status,
    v.visit_type,
    v.is_client_billable
from {{ ref('stg_visits') }} as v
left join {{ ref('stg_routes') }} as r on v.route_id = r.route_id
left join main_worker as mw on r.route_id = mw.route_id
