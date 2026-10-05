select
    fr.answer_id,
    fr.visit_id,
    dc.client_name,
    dc.project_name,
    dc.project_type,
    fr.campaign_id,
    dc.campaign_name,
    fr.visit_date,
    cast(date_trunc('month', fr.visit_date) as date) as visit_month,
    fr.visit_status,
    fr.intervention_point_id,
    dp.intervention_point_name,
    dp.intervention_point_province,
    fr.question_id,
    dq.question_name,
    dq.question_category,
    -- both sources agree when both exist
    coalesce(dq.question_type, fr.question_type) as question_type,
    dq.question_is_highlighted,
    fr.answer,
    -- done visits, yes or no only
    case
        when {{ is_done_status('fr.visit_status') }}
            and dq.question_name ilike '%quiere realizar pedido%'
            and fr.answer in ('Si', 'No')
        then fr.answer = 'Si'
    end as wants_to_order,
    -- done visits, blank counts as no
    case
        when {{ is_done_status('fr.visit_status') }}
            and dq.question_name ilike '%Resultado de la formaci%'
        then coalesce(fr.answer like '%OK%', false)
    end as accepts_training
from {{ ref('fct_responses') }} as fr
left join {{ ref('dim_campaign') }} as dc on fr.campaign_id = dc.campaign_id
left join {{ ref('dim_question') }} as dq on fr.question_id = dq.question_id
left join {{ ref('dim_pos') }} as dp on fr.intervention_point_id = dp.intervention_point_id
