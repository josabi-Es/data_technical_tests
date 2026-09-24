{{ config(severity='warn') }}

select
    visits.visit_id,
    visits.visit_date,
    campaigns.campaign_start_date,
    campaigns.campaign_end_date
from {{ ref('stg_visits') }} as visits
join {{ ref('stg_campaigns') }} as campaigns
    on visits.campaign_id = campaigns.campaign_id
where visits.visit_date not between campaigns.campaign_start_date and campaigns.campaign_end_date
