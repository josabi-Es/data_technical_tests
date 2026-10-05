{% test no_inverted_article(model, column_name) %}
-- blocks values like Rioja, La
select {{ column_name }}
from {{ model }}
where regexp_matches({{ column_name }}, ', (LA|LAS|EL|LOS)$')
{% endtest %}
