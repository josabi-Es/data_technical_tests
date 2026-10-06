{{ config(
    materialized='incremental',
    unique_key='visit_id',
    on_schema_change='fail'
) }}

with src as (
    select
        visits.visit_id,
        coalesce(pos.pos_key, '-1') as pos_key,
        coalesce(routes.route_key, -1) as route_key,
        coalesce(campaigns.campaign_key, -1) as campaign_key,
        coalesce(status.status_key, -1) as status_key,
        coalesce(dates.date_key, -1) as date_key,
        visits.visit_date,
        visits.updated_at,
        coalesce(status.is_completed, false) as is_completed,
        coalesce(status.is_incidence, false) as is_incidence
    from {{ ref('stg_visits') }} as visits
    left join {{ ref('dim_pos') }} as pos
        on visits.intervention_point_id = pos.intervention_point_id
    left join {{ ref('dim_route') }} as routes
        on visits.route_id = routes.route_key
    left join {{ ref('dim_campaign') }} as campaigns
        on visits.campaign_id = campaigns.campaign_key
    left join {{ ref('dim_visit_status') }} as status
        on visits.visit_status = status.visit_status
    left join {{ ref('dim_date') }} as dates
        on visits.visit_date = dates.date_day
)

select
    src.visit_id,
    src.pos_key,
    src.route_key,
    src.campaign_key,
    src.status_key,
    src.date_key,
    src.visit_date,
    src.updated_at,
    src.is_completed,
    src.is_incidence
from src
{% if is_incremental() %}
{# row by row, no fixed margin #}
left join {{ this }} as tgt
    on src.visit_id = tgt.visit_id
where tgt.visit_id is null
    or src.updated_at > tgt.updated_at
{% endif %}
