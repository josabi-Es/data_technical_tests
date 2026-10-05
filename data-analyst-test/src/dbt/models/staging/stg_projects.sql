with source as (

    select
        project_id,
        project_name,
        client_id
    from {{ source('raw', 'raw_projects') }}

),

renamed as (

    select
        project_id,
        {{ clean_string('project_name') }} as project_name,
        regexp_extract({{ clean_string('project_name') }}, 'Proyecto (.+?) [0-9]+', 1) as project_type,
        client_id
    from source

)

select * from renamed
