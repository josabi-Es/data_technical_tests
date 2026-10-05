{# one definition of done #}
{% macro is_done_status(column_name) -%}
    {{ column_name }} in ('OK', 'INCID', 'INFO')
{%- endmacro %}
