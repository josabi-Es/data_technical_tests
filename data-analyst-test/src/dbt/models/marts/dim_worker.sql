select
    employee_id,
    employee_first_name,
    employee_active_status,
    employee_address_province,
    employee_contract_type
from {{ ref('stg_workers') }}
