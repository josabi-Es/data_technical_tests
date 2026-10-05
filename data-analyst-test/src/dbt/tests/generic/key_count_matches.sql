{% test key_count_matches(model, column_name, compare_model, compare_column) %}
-- fails when key counts differ
with model_keys as (select count(distinct {{ column_name }}) as n from {{ model }}),
compare_keys as (select count(distinct {{ compare_column }}) as n from {{ compare_model }})
select model_keys.n as model_keys, compare_keys.n as compare_keys
from model_keys
cross join compare_keys
where model_keys.n <> compare_keys.n
{% endtest %}
