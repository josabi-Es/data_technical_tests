-- at most one main worker
select
    route_id,
    count(*) as main_workers
from {{ ref('bridge_route_worker') }}
where main_employee
group by route_id
having count(*) > 1
