{% macro normalize_string(column_name) %}
    regexp_replace(lower({{ clean_string(column_name) }}), '\s(s\.l\.|s\.a\.)$', '')
{% endmacro %}
