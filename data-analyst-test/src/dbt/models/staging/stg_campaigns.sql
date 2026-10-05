with source as (

    select
        campaign_id,
        campaign_code,
        campaign_name,
        project_id,
        campaign_start_date,
        campaign_end_date,
        is_active,
        campaign_state,
        total_visits_planned,
        total_pos_planned,
        visit_duration_minutes
    from {{ source('raw', 'raw_campaigns') }}

),

renamed as (

    select
        campaign_id,
        {{ clean_string('campaign_code') }} as campaign_code,
        {{ clean_string('campaign_name') }} as campaign_name,
        project_id,
        campaign_start_date,
        campaign_end_date,
        is_active,
        coalesce(upper({{ clean_string('campaign_state') }}), 'UNKNOWN') as campaign_state,
        total_visits_planned,
        total_pos_planned,
        visit_duration_minutes
    from source

)

select * from renamed
