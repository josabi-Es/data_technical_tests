with main_routes as (

    select
        employee_id,
        count(*) as routes_as_main
    from {{ ref('bridge_route_worker') }}
    where main_employee
    group by employee_id

),

visits_agg as (

    select
        employee_id,
        count(*) as visits_recorded,
        count(*) filter (where {{ is_done_status('visit_status') }}) as visits_done,
        count(distinct visit_date) as active_days
    from {{ ref('fct_visits') }}
    where employee_id is not null
    group by employee_id

)

select
    dw.employee_id,
    dw.employee_first_name,
    dw.employee_address_province,
    coalesce(mr.routes_as_main, 0) as routes_as_main,
    va.visits_recorded,
    va.visits_done,
    va.active_days,
    round(va.visits_done * 1.0 / nullif(va.active_days, 0), 2) as visits_per_active_day
from {{ ref('dim_worker') }} as dw
-- workers without visits drop out
join visits_agg as va on dw.employee_id = va.employee_id
left join main_routes as mr on dw.employee_id = mr.employee_id
