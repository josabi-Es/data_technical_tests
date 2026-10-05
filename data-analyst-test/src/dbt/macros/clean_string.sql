{% macro clean_string(column_name) %}
    nullif(trim(regexp_replace({{ column_name }}, '\s+', ' ', 'g')), '')
{% endmacro %}
