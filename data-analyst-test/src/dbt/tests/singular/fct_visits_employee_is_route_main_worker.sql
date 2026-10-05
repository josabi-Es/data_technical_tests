-- visit worker is the main worker
select fv.visit_id
from {{ ref('fct_visits') }} as fv
left join {{ ref('bridge_route_worker') }} as b
    on fv.route_id = b.route_id and b.main_employee
where fv.employee_id is distinct from b.employee_id
