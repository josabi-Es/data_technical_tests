select
    (select count(*) from {{ ref('stg_visits') }}) as staging_rows,
    (select count(*) from {{ ref('fct_visits') }}) as fact_rows
where (select count(*) from {{ ref('stg_visits') }}) <> (select count(*) from {{ ref('fct_visits') }})
