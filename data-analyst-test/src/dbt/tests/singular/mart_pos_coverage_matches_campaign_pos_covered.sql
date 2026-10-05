-- points per campaign equal the campaign mart
with coverage as (
    select campaign_id, count(*) as pos_covered
    from {{ ref('mart_pos_coverage') }}
    group by campaign_id
)

select m.campaign_id, m.pos_covered as mart_pos_covered, coalesce(c.pos_covered, 0) as coverage_pos
from {{ ref('mart_campaign_performance') }} as m
left join coverage as c on m.campaign_id = c.campaign_id
where m.is_campaign_total
  and m.pos_covered <> coalesce(c.pos_covered, 0)
