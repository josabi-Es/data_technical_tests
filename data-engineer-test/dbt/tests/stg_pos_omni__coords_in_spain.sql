select intervention_point_id, latitude, longitude
from {{ ref('stg_pos_omni') }}
where latitude is not null
    and (
        latitude not between {{ var('spain_lat_min') }} and {{ var('spain_lat_max') }}
        or longitude not between {{ var('spain_lon_min') }} and {{ var('spain_lon_max') }}
    )
