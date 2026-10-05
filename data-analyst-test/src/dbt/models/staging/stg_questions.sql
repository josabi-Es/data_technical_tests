with source as (

    select
        question_id,
        campaign_id,
        question_name,
        question_type,
        question_category,
        question_order,
        question_is_highlighted
    from {{ source('raw', 'raw_questions') }}

),

renamed as (

    select
        question_id,
        campaign_id,
        {{ clean_string('question_name') }} as question_name,
        upper({{ clean_string('question_type') }}) as question_type,
        {{ clean_string('question_category') }} as question_category,
        question_order,
        question_is_highlighted
    from source

)

select * from renamed
