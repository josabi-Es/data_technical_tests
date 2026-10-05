select
    route_employee_id,
    route_id,
    employee_id,
    main_employee,
    ip_percentage
from {{ ref('stg_route_employee') }}
