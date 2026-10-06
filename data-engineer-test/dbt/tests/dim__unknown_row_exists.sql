select 'dim_pos' as model_name
where not exists (select 1 from {{ ref('dim_pos') }} where pos_key = '-1')

union all

select 'dim_campaign'
where not exists (select 1 from {{ ref('dim_campaign') }} where campaign_key = -1)

union all

select 'dim_route'
where not exists (select 1 from {{ ref('dim_route') }} where route_key = -1)

union all

select 'dim_date'
where not exists (select 1 from {{ ref('dim_date') }} where date_key = -1)

union all

select 'dim_visit_status'
where not exists (select 1 from {{ ref('dim_visit_status') }} where status_key = -1)
