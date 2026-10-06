with visits as (
    select
        campaign_key,
        count(*)::integer as visits_total,
        count(*) filter (where is_completed)::integer as visits_completed,
        count(*) filter (where is_incidence)::integer as visits_incidence
    from {{ ref('fct_visits') }}
    group by campaign_key
)

select
    campaigns.campaign_id as campaign_key,
    campaigns.total_visits_planned,
    coalesce(visits.visits_total, 0) as visits_total,
    coalesce(visits.visits_completed, 0) as visits_completed,
    coalesce(visits.visits_incidence, 0) as visits_incidence,
    round(
        coalesce(visits.visits_completed, 0)::numeric
        / nullif(campaigns.total_visits_planned, 0),
        4
    )::numeric(8, 4) as completion_rate
from {{ ref('stg_campaigns') }} as campaigns
left join visits
    on campaigns.campaign_id = visits.campaign_key
