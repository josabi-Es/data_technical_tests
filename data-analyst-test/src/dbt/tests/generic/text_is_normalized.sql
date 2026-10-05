{% test text_is_normalized(model, column_name) %}
-- upper case, no accents, no edge spaces
select {{ column_name }}
from {{ model }}
where {{ column_name }} is not null
  and {{ column_name }} <> upper(strip_accents(trim({{ column_name }})))
{% endtest %}
