{% test grain_is_unique(model, combination_of_columns) %}
-- grain must not repeat
select {{ combination_of_columns | join(', ') }}, count(*) as n
from {{ model }}
group by {{ combination_of_columns | join(', ') }}
having count(*) > 1
{% endtest %}
