with source as (

    select
        route_employee_id,
        route_id,
        employee_id,
        main_employee,
        ip_percentage,
        deleted_at
    from {{ source('raw', 'raw_route_employee') }}

),

renamed as (

    select
        route_employee_id,
        route_id,
        employee_id,
        main_employee,
        ip_percentage
    from source
    where deleted_at is null

)

select * from renamed
