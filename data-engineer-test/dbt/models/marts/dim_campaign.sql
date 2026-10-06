select
    campaigns.campaign_id as campaign_key,
    campaigns.campaign_name,
    campaigns.campaign_start_date,
    campaigns.campaign_end_date,
    projects.project_id,
    projects.project_name,
    projects.client_code
from {{ ref('stg_campaigns') }} as campaigns
left join {{ ref('stg_projects') }} as projects
    on campaigns.project_id = projects.project_id

union all

{# unknown row #}
select
    -1,
    'UNKNOWN',
    null::date,
    null::date,
    -1,
    'UNKNOWN',
    'UNKNOWN'
