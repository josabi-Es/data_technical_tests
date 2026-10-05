with source as (

    select
        client_id,
        client_name,
        country,
        sector
    from {{ source('raw', 'raw_clients') }}

),

renamed as (

    select
        client_id,
        {{ clean_string('client_name') }} as client_name,
        {{ normalize_country('country') }} as country,
        {{ clean_string('sector') }} as sector
    from source

)

select distinct * from renamed
