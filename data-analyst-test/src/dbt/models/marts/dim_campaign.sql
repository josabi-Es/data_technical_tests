select
    c.client_id,
    c.client_name,
    c.sector,
    p.project_id,
    p.project_name,
    p.project_type,
    ca.campaign_id,
    ca.campaign_name,
    ca.campaign_start_date,
    ca.campaign_end_date,
    ca.visit_duration_minutes,
    ca.total_visits_planned,
    ca.total_pos_planned
from {{ ref('stg_campaigns') }} as ca
left join {{ ref('stg_projects') }} as p on ca.project_id = p.project_id
left join {{ ref('stg_clients') }} as c on p.client_id = c.client_id
