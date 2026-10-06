select
    (select count(*) from {{ source('raw', 'raw_visits') }}) as raw_rows,
    (select count(*) from {{ ref('stg_visits') }}) as staging_rows
where (select count(*) from {{ source('raw', 'raw_visits') }}) <> (select count(*) from {{ ref('stg_visits') }})
