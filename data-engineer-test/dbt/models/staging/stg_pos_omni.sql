with source as (

    select
        intervention_point_id,
        intervention_point_code,
        intervention_point_name,
        intervention_point_address,
        intervention_point_province,
        intervention_point_locality,
        intervention_point_postal_code,
        intervention_point_latitude,
        intervention_point_longitude,
        intervention_point_is_active,
        created_at,
        updated_at
    from {{ source('raw', 'pos_omni') }}

),

renamed as (

    select
        intervention_point_id::integer as intervention_point_id,
        {{ clean_string('intervention_point_code') }} as intervention_point_code,
        {{ clean_string('intervention_point_name') }} as name,
        {{ normalize_string('intervention_point_name') }} as name_normalized,
        {{ clean_string('intervention_point_address') }} as address,
        trim(split_part(intervention_point_address, ' Nº ', 1)) as street,
        split_part(intervention_point_address, ' Nº ', 2)::integer as door_number,
        {{ clean_string('intervention_point_postal_code') }} as postal_code,
        {{ clean_string('intervention_point_locality') }} as locality,
        upper({{ clean_string('intervention_point_province') }}) as province,
        intervention_point_latitude::numeric(9, 6) as latitude,
        intervention_point_longitude::numeric(9, 6) as longitude,
        intervention_point_is_active::boolean as is_active,
        created_at::date as created_at,
        updated_at::date as updated_at
    from source

)

select * from renamed
