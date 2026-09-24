with source as (

    select
        project_id,
        client_code,
        project_name,
        created_at,
        updated_at
    from {{ source('raw', 'raw_projects') }}

),

renamed as (

    select
        project_id::integer as project_id,
        upper({{ clean_string('client_code') }}) as client_code,
        {{ clean_string('project_name') }} as project_name,
        created_at::date as created_at,
        updated_at::date as updated_at
    from source

)

select * from renamed
