select pos_id, latitude, longitude
from {{ ref('dim_pos_unified') }}
where latitude is not null
    and (
        latitude not between 27 and 44
        or longitude not between -19 and 5
    )
