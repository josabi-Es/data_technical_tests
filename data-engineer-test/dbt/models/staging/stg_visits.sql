with source as (

    select
        visit_id,
        intervention_point_id,
        route_id,
        campaign_id,
        visit_date,
        visit_status,
        created_at,
        updated_at
    from {{ source('raw', 'raw_visits') }}

),

renamed as (

    select
        visit_id::integer as visit_id,
        intervention_point_id::integer as intervention_point_id,
        route_id::integer as route_id,
        campaign_id::integer as campaign_id,
        visit_date::date as visit_date,
        upper({{ clean_string('visit_status') }}) as visit_status,
        created_at::date as created_at,
        updated_at::date as updated_at
    from source

)

select * from renamed
