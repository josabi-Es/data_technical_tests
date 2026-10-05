-- question and answer agree on type
select fr.answer_id, dq.question_type as question_side, fr.question_type as answer_side
from {{ ref('fct_responses') }} as fr
join {{ ref('dim_question') }} as dq on fr.question_id = dq.question_id
where fr.question_type is not null
  and dq.question_type is not null
  and fr.question_type <> dq.question_type
