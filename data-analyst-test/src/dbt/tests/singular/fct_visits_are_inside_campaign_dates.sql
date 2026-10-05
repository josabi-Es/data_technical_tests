{{ config(severity='warn') }}

select
    fv.visit_id,
    fv.visit_date,
    dc.campaign_start_date,
    dc.campaign_end_date
from {{ ref('fct_visits') }} as fv
join {{ ref('dim_campaign') }} as dc on fv.campaign_id = dc.campaign_id
where fv.visit_date not between dc.campaign_start_date and dc.campaign_end_date
