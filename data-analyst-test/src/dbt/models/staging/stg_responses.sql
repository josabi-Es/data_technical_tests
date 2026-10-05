with source as (

    select
        answer_id,
        visit_id,
        question_id,
        question_type,
        answer,
        expected_answer
    from {{ source('raw', 'raw_responses') }}

),

renamed as (

    select
        answer_id,
        visit_id,
        question_id,
        upper({{ clean_string('question_type') }}) as question_type,
        {{ clean_string('answer') }} as answer,
        {{ clean_string('expected_answer') }} as expected_answer
    from source

)

select * from renamed
