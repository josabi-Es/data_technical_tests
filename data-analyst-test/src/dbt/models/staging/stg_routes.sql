with source as (

    select
        route_id,
        route_code,
        route_name,
        campaign_id,
        route_start_date,
        route_end_date,
        route_status,
        delegation_code
    from {{ source('raw', 'raw_routes') }}

),

renamed as (

    select
        route_id,
        {{ clean_string('route_code') }} as route_code,
        {{ clean_string('route_name') }} as route_name,
        campaign_id,
        route_start_date,
        route_end_date,
        coalesce(upper({{ clean_string('route_status') }}), 'UNKNOWN') as route_status,
        {{ clean_string('delegation_code') }} as delegation_code
    from source

)

select * from renamed
