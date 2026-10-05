select
    question_id,
    campaign_id,
    question_name,
    question_type,
    question_category,
    question_order,
    question_is_highlighted
from {{ ref('stg_questions') }}
