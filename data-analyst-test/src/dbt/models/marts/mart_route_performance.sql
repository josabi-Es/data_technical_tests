with reference as (

    select max(visit_date) as reference_date
    from {{ ref('fct_visits') }}

),

visits_agg as (

    select
        route_id,
        count(*) as total_visits
    from {{ ref('fct_visits') }}
    where route_id <> -1
    group by route_id

)

select
    dr.route_id,
    dr.route_code,
    dr.route_name,
    dc.client_name,
    dc.project_name,
    dc.project_type,
    dr.campaign_id,
    dc.campaign_name,
    dr.route_start_date,
    dr.route_end_date,
    dr.route_status,
    coalesce(va.total_visits, 0) as total_visits,
    r.reference_date,
    (dr.route_end_date < r.reference_date) as is_closed,
    (dr.route_end_date < r.reference_date and coalesce(va.total_visits, 0) = 0) as is_closed_without_visits,
    case
        when dr.route_end_date < r.reference_date and coalesce(va.total_visits, 0) = 0
        then date_diff('day', dr.route_end_date, r.reference_date)
    end as days_since_closed
from {{ ref('dim_route') }} as dr
-- inner join drops the no route row
join {{ ref('dim_campaign') }} as dc on dr.campaign_id = dc.campaign_id
left join visits_agg as va on dr.route_id = va.route_id
cross join reference as r
