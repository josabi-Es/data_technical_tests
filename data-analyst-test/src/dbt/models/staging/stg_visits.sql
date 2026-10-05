with source as (

    select
        visit_id,
        campaign_id,
        intervention_point_id,
        route_id,
        visit_date,
        visit_time,
        visit_status,
        visit_type,
        is_client_billable
    from {{ source('raw', 'raw_visits') }}

),

renamed as (

    select
        visit_id,
        campaign_id,
        intervention_point_id,
        route_id,
        visit_date,
        visit_time,
        coalesce(upper({{ clean_string('visit_status') }}), 'UNKNOWN') as visit_status,
        {{ clean_string('visit_type') }} as visit_type,
        is_client_billable
    from source

)

select distinct * from renamed
