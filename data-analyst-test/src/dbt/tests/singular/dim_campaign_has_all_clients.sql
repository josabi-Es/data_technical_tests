-- no client lost in the join
select c.client_id
from {{ ref('stg_clients') }} as c
left join (
    select distinct client_id
    from {{ ref('dim_campaign') }}
) as dc on c.client_id = dc.client_id
where dc.client_id is null
