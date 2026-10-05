with source as (

    select
        employee_id,
        employee_first_name,
        employee_active_status,
        employee_hire_date,
        employee_address_province,
        employee_contract_type
    from {{ source('raw', 'raw_workers') }}

),

renamed as (

    select
        employee_id,
        {{ clean_string('employee_first_name') }} as employee_first_name,
        employee_active_status,
        employee_hire_date,
        {{ normalize_province('employee_address_province') }} as employee_address_province,
        upper({{ clean_string('employee_contract_type') }}) as employee_contract_type
    from source

)

select distinct * from renamed
