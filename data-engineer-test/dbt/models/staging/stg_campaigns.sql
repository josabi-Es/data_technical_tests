with source as (

    select
        campaign_id,
        project_id,
        campaign_name,
        campaign_start_date,
        campaign_end_date,
        total_visits_planned,
        created_at,
        updated_at
    from {{ source('raw', 'raw_campaigns') }}

),

renamed as (

    select
        campaign_id::integer as campaign_id,
        project_id::integer as project_id,
        {{ clean_string('campaign_name') }} as campaign_name,
        campaign_start_date::date as campaign_start_date,
        campaign_end_date::date as campaign_end_date,
        total_visits_planned::integer as total_visits_planned,
        created_at::date as created_at,
        updated_at::date as updated_at
    from source

)

select * from renamed
