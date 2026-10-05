with reference as (

    select max(visit_date) as reference_date
    from {{ ref('fct_visits') }}

),

visit_rows as (

    select
        campaign_id,
        cast(date_trunc('month', visit_date) as date) as visit_month,
        intervention_point_id,
        visit_status,
        is_client_billable
    from {{ ref('fct_visits') }}

),

-- one row per month, one total per campaign
visits_agg as (

    select
        campaign_id,
        visit_month,
        grouping(visit_month) = 1 as is_campaign_total,
        count(*) as visits_recorded,
        count(*) filter (where {{ is_done_status('visit_status') }}) as visits_done,
        count(*) filter (where visit_status = 'OK') as visits_ok,
        count(*) filter (where visit_status = 'INCID') as visits_incident,
        count(*) filter (where visit_status = 'INFO') as visits_info,
        count(*) filter (where visit_status = 'NOVIS') as visits_not_done,
        count(*) filter (where visit_status = 'UNKNOWN') as visits_unknown,
        count(*) filter (
            where {{ is_done_status('visit_status') }} and is_client_billable
        ) as visits_billable,
        count(*) filter (
            where {{ is_done_status('visit_status') }} and is_client_billable is not null
        ) as visits_with_billing_flag,
        count(distinct intervention_point_id) filter (
            where {{ is_done_status('visit_status') }}
        ) as pos_covered
    from visit_rows
    group by grouping sets ((campaign_id, visit_month), (campaign_id))
    -- undated visits only in the total
    having not (grouping(visit_month) = 0 and visit_month is null)

),

joined as (

    select
        dc.client_name,
        dc.project_name,
        dc.project_type,
        dc.campaign_id,
        dc.campaign_name,
        dc.campaign_start_date,
        dc.campaign_end_date,
        dc.visit_duration_minutes,
        va.visit_month,
        coalesce(va.is_campaign_total, true) as is_campaign_total,
        coalesce(va.visits_recorded, 0) as visits_recorded,
        coalesce(va.visits_done, 0) as visits_done,
        coalesce(va.visits_ok, 0) as visits_ok,
        coalesce(va.visits_incident, 0) as visits_incident,
        coalesce(va.visits_info, 0) as visits_info,
        coalesce(va.visits_not_done, 0) as visits_not_done,
        coalesce(va.visits_unknown, 0) as visits_unknown,
        coalesce(va.visits_billable, 0) as visits_billable,
        coalesce(va.visits_with_billing_flag, 0) as visits_with_billing_flag,
        coalesce(va.pos_covered, 0) as pos_covered,
        r.reference_date
    from {{ ref('dim_campaign') }} as dc
    left join visits_agg as va on dc.campaign_id = va.campaign_id
    cross join reference as r

)

select
    client_name,
    project_name,
    project_type,
    campaign_id,
    campaign_name,
    -- phase from dates
    case
        when campaign_start_date is null or campaign_end_date is null then 'Unknown'
        when campaign_start_date > reference_date then 'Not started'
        when campaign_end_date < reference_date then 'Closed'
        else 'Active'
    end as campaign_phase,
    visit_month,
    is_campaign_total,
    visits_recorded,
    visits_done,
    visits_ok,
    visits_incident,
    visits_info,
    visits_not_done,
    visits_unknown,
    round(visits_not_done * 1.0 / nullif(visits_recorded, 0), 3) as pct_not_done,
    pos_covered,
    visits_billable,
    visits_with_billing_flag,
    round(visits_billable * 1.0 / nullif(visits_with_billing_flag, 0), 3) as pct_billable,
    visits_done * visit_duration_minutes / 60.0 as field_hours,
    reference_date
from joined
