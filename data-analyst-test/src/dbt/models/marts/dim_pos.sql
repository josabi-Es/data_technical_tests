select
    intervention_point_id,
    intervention_point_name,
    intervention_point_province,
    intervention_point_locality,
    intervention_point_latitude,
    intervention_point_longitude,
    intervention_point_is_active
from {{ ref('stg_pos') }}
