{{ config(severity='warn') }}

-- routes left without a main worker
select dr.route_id
from {{ ref('dim_route') }} as dr
left join (
    select distinct route_id
    from {{ ref('bridge_route_worker') }}
    where main_employee
) as mw on dr.route_id = mw.route_id
where dr.route_id <> -1
  and mw.route_id is null
