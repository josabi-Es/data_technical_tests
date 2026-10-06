select 'stg_pos_omni' as model_name, upper(province) as province
from {{ ref('stg_pos_omni') }}
group by upper(province)
having count(distinct province) > 1

union all

select 'stg_workers' as model_name, upper(employee_address_province) as province
from {{ ref('stg_workers') }}
group by upper(employee_address_province)
having count(distinct employee_address_province) > 1
