{% macro normalize_country(column_name) %}
    case
        when upper(strip_accents(trim({{ column_name }}))) in ('SPAIN', 'ESPANA') then 'SPAIN'
        else upper(strip_accents(trim({{ column_name }})))
    end
{% endmacro %}
