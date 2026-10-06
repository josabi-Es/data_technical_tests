select visit_id
from {{ ref('fct_visits') }}
where pos_key is null
    or route_key is null
    or campaign_key is null
    or status_key is null
    or date_key is null
