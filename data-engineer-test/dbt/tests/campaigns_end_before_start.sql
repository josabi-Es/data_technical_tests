select campaign_id, campaign_start_date, campaign_end_date
from {{ ref('stg_campaigns') }}
where campaign_end_date < campaign_start_date
