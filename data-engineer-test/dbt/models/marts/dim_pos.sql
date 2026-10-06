with omni as (
    select
        intervention_point_id,
        name,
        name_normalized,
        street,
        door_number,
        postal_code,
        province,
        latitude,
        longitude,
        is_active
    from {{ ref('stg_pos_omni') }}
),

gi as (
    select
        ext_id,
        name,
        name_normalized,
        street,
        door_number,
        postal_code,
        is_active
    from {{ ref('stg_pos_gi') }}
),

{# level 1 exact rule #}
candidates as (
    select
        omni.intervention_point_id,
        gi.ext_id,
        'NAME_POSTAL_CODE' as match_rule,
        {{ var('match_confidence_exact') }} as confidence
    from omni
    inner join gi
        on omni.name_normalized = gi.name_normalized
        and omni.postal_code = gi.postal_code

    union all

    {# level 2 postal code typo #}
    select
        omni.intervention_point_id,
        gi.ext_id,
        'NAME_ADDRESS' as match_rule,
        {{ var('match_confidence_address') }} as confidence
    from omni
    inner join gi
        on omni.name_normalized = gi.name_normalized
        and omni.street = gi.street
        and omni.door_number = gi.door_number
        and abs(omni.postal_code::integer - gi.postal_code::integer) = {{ var('postal_code_distance') }}
),

{# keep one to one #}
ranked as (
    select
        intervention_point_id,
        ext_id,
        match_rule,
        confidence,
        row_number() over (partition by intervention_point_id order by confidence desc, ext_id) as rank_omni,
        row_number() over (partition by ext_id order by confidence desc, intervention_point_id) as rank_gi
    from candidates
),

matches as (
    select intervention_point_id, ext_id, match_rule, confidence
    from ranked
    where rank_omni = 1 and rank_gi = 1
),

joined as (
    select
        omni.intervention_point_id,
        gi.ext_id,
        coalesce(omni.name, gi.name) as name,
        coalesce(omni.name_normalized, gi.name_normalized) as name_normalized,
        coalesce(omni.street, gi.street) as street,
        coalesce(omni.door_number, gi.door_number) as door_number,
        coalesce(omni.postal_code, gi.postal_code) as postal_code,
        omni.province,
        omni.latitude,
        omni.longitude,
        coalesce(omni.is_active, gi.is_active) as is_active,
        matches.match_rule,
        matches.confidence
    from omni
    left join matches
        on omni.intervention_point_id = matches.intervention_point_id
    full outer join gi
        on matches.ext_id = gi.ext_id
),

stores as (
    select
        md5(coalesce('omni:' || intervention_point_id::text, 'gi:' || ext_id)) as pos_key,
        intervention_point_id,
        ext_id,
        name,
        name_normalized,
        street,
        door_number,
        postal_code,
        province,
        latitude,
        longitude,
        is_active,
        case
            when intervention_point_id is not null and ext_id is not null then 'MATCHED'
            when intervention_point_id is not null then 'OMNI_ONLY'
            else 'GI_ONLY'
        end as match_status,
        case
            when intervention_point_id is not null and ext_id is not null then 'OMNI+GI'
            when intervention_point_id is not null then 'OMNI'
            else 'GI'
        end as source_system,
        match_rule,
        confidence
    from joined
)

select
    pos_key,
    intervention_point_id,
    ext_id,
    name,
    name_normalized,
    street,
    door_number,
    postal_code,
    province,
    latitude,
    longitude,
    is_active,
    match_status,
    source_system,
    match_rule,
    confidence
from stores

union all

{# unknown row #}
select
    '-1',
    null::integer,
    null::text,
    'UNKNOWN',
    'unknown',
    null::text,
    null::integer,
    'UNKNOWN',
    null::text,
    null::numeric(9,6),
    null::numeric(9,6),
    false,
    'UNKNOWN',
    'UNKNOWN',
    null::text,
    null::numeric
