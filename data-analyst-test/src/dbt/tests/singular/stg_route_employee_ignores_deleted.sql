-- deleted assignments are filtered
select raw_rows, stg_rows
from (
    select count(*) as raw_rows
    from {{ source('raw', 'raw_route_employee') }}
    where deleted_at is null
) as r
cross join (
    select count(*) as stg_rows
    from {{ ref('stg_route_employee') }}
) as s
where raw_rows <> stg_rows
