select
    a.answer_id,
    a.visit_id,
    a.question_id,
    -- 288 answers have no question
    coalesce(q.campaign_id, v.campaign_id) as campaign_id,
    v.intervention_point_id,
    v.visit_date,
    v.visit_status,
    a.question_type,
    a.answer
from {{ ref('stg_responses') }} as a
left join {{ ref('stg_visits') }} as v on a.visit_id = v.visit_id
left join {{ ref('stg_questions') }} as q on a.question_id = q.question_id
