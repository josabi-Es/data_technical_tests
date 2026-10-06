select pos_key, match_rule, confidence
from {{ ref('dim_pos') }}
where match_status = 'MATCHED'
    and (
        confidence not between 0 and 1
        or (match_rule = 'NAME_POSTAL_CODE' and confidence <> {{ var('match_confidence_exact') }})
        or (match_rule = 'NAME_ADDRESS' and confidence <> {{ var('match_confidence_address') }})
    )
