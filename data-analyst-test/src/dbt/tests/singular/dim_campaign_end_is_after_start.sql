{{ config(severity='warn') }}

select
    campaign_id,
    campaign_start_date,
    campaign_end_date
from {{ ref('dim_campaign') }}
where campaign_end_date < campaign_start_date
