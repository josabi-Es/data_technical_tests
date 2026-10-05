{% test row_count_matches(model, compare_model, offset=0) %}
-- fails when row counts differ
with model_rows as (select count(*) as n from {{ model }}),
expected_rows as (select count(*) + {{ offset }} as n from {{ compare_model }})
select model_rows.n as model_rows, expected_rows.n as expected_rows
from model_rows
cross join expected_rows
where model_rows.n <> expected_rows.n
{% endtest %}
