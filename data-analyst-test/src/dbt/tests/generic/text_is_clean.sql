{% test text_is_clean(model, column_name) %}
-- no edge spaces, double spaces or empty text
select {{ column_name }}
from {{ model }}
where {{ column_name }} is not null
  and ({{ column_name }} = ''
       or {{ column_name }} <> trim(regexp_replace({{ column_name }}, '\s+', ' ', 'g')))
{% endtest %}
