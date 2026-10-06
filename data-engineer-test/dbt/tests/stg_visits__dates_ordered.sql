{{ config(severity='warn') }}

select visit_id, visit_date, created_at, updated_at
from {{ ref('stg_visits') }}
where visit_date < created_at
    or updated_at < visit_date
