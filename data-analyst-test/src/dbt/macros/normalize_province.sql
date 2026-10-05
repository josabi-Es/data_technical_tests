{% macro normalize_province(column_name) %}
    {%- set base -%}
        regexp_replace(upper(strip_accents({{ clean_string(column_name) }})), '^(.+), (LA|LAS|EL|LOS)$', '\2 \1')
    {%- endset -%}
    case
        when {{ base }} = 'CASTELLO' then 'CASTELLON'
        when {{ base }} = 'VALENCIA/VALENCIA' then 'VALENCIA'
        else {{ base }}
    end
{% endmacro %}
