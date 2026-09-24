with source as (

    select
        employee_id,
        employee_first_name,
        employee_active_status,
        employee_address_province,
        employee_contract_type,
        created_at
    from {{ source('raw', 'raw_workers') }}

),

renamed as (

    select
        employee_id::integer as employee_id,
        {{ clean_string('employee_first_name') }} as employee_first_name,
        employee_active_status::boolean as employee_active_status,
        upper({{ clean_string('employee_address_province') }}) as employee_address_province,
        upper({{ clean_string('employee_contract_type') }}) as employee_contract_type,
        created_at::date as created_at
    from source

)

select * from renamed
