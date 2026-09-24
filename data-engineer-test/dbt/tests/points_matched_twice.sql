select intervention_point_id::text as source_id
from {{ ref('dim_pos_unified') }}
where match_status = 'MATCHED'
group by intervention_point_id
having count(*) > 1

union all

select ext_id as source_id
from {{ ref('dim_pos_unified') }}
where match_status = 'MATCHED'
group by ext_id
having count(*) > 1
