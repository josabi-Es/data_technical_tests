{{ config(severity='warn') }}

-- not done visits that have a form
select distinct visit_id
from {{ ref('fct_responses') }}
where visit_status = 'NOVIS'
