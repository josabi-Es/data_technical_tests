with source as (

    select
        intervention_point_id,
        intervention_point_name,
        intervention_point_address,
        intervention_point_province,
        intervention_point_locality,
        intervention_point_postal_code,
        intervention_point_latitude,
        intervention_point_longitude,
        intervention_point_is_active
    from {{ source('raw', 'raw_pos') }}

),

renamed as (

    select
        intervention_point_id,
        {{ clean_string('intervention_point_name') }} as intervention_point_name,
        {{ clean_string('intervention_point_address') }} as intervention_point_address,
        {{ normalize_province('intervention_point_province') }} as intervention_point_province,
        {{ clean_string('intervention_point_locality') }} as intervention_point_locality,
        intervention_point_postal_code,
        intervention_point_latitude,
        intervention_point_longitude,
        intervention_point_is_active
    from source

)

select * from renamed
