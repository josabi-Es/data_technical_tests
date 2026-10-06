select
    facts.visit_id,
    facts.route_key,
    facts.campaign_key as fct_campaign_key,
    routes.campaign_key as route_campaign_key
from {{ ref('fct_visits') }} as facts
inner join {{ ref('dim_route') }} as routes
    on facts.route_key = routes.route_key
where facts.route_key <> -1
    and facts.campaign_key <> routes.campaign_key
