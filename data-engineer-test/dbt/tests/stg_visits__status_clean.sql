select visit_id, visit_status
from {{ ref('stg_visits') }}
where visit_status <> upper(trim(visit_status))
    or visit_status ~ '\s{2,}'
