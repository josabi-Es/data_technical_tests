with source as (

    select
        route_id,
        campaign_id,
        route_start_date,
        route_end_date,
        route_status,
        created_at
    from {{ source('raw', 'raw_routes') }}

),

renamed as (

    select
        route_id::integer as route_id,
        campaign_id::integer as campaign_id,
        route_start_date::date as route_start_date,
        route_end_date::date as route_end_date,
        upper({{ clean_string('route_status') }}) as route_status,
        created_at::date as created_at
    from source

)

select * from renamed
