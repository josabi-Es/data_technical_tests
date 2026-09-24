with source as (

    select
        ext_id,
        point_name,
        address_street,
        address_number,
        address_city,
        address_zip,
        is_active
    from {{ source('raw', 'pos_gi') }}

),

renamed as (

    select
        {{ clean_string('ext_id') }} as ext_id,
        {{ clean_string('point_name') }} as name,
        {{ normalize_string('point_name') }} as name_normalized,
        {{ clean_string('address_street') }} as street,
        address_number::integer as door_number,
        {{ clean_string('address_zip') }} as postal_code,
        {{ clean_string('address_city') }} as city,
        is_active::boolean as is_active
    from source

)

select * from renamed
