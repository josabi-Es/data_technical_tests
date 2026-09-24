{{ config(
    materialized='incremental',
    unique_key='visit_id',
    on_schema_change='fail'
) }}

select
    visits.visit_id,
    pos.pos_id,
    visits.intervention_point_id,
    visits.route_id,
    coalesce(routes.route_status, 'UNKNOWN') as route_status,
    visits.campaign_id,
    campaigns.campaign_name,
    campaigns.project_id,
    projects.project_name,
    projects.client_code,
    visits.visit_date,
    coalesce(visits.visit_status, 'UNKNOWN') as visit_status,
    visits.created_at,
    visits.updated_at
from {{ ref('stg_visits') }} as visits
left join {{ ref('dim_pos_unified') }} as pos
    on visits.intervention_point_id = pos.intervention_point_id
left join {{ ref('stg_routes') }} as routes
    on visits.route_id = routes.route_id
left join {{ ref('stg_campaigns') }} as campaigns
    on visits.campaign_id = campaigns.campaign_id
left join {{ ref('stg_projects') }} as projects
    on campaigns.project_id = projects.project_id

{% if is_incremental() %}
{# three day margin for late rows #}
where visits.updated_at >= (select max(updated_at) - interval '3 days' from {{ this }})
{% endif %}
