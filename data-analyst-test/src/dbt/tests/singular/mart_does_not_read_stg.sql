-- kpi marts read the model only
{% set offenders = [] %}
{% for node in graph.nodes.values() if node.resource_type == 'model' and node.name.startswith('mart_') %}
    {% for dep in node.depends_on.nodes if '.stg_' in dep %}
        {% do offenders.append(node.name ~ ' reads ' ~ dep) %}
    {% endfor %}
{% endfor %}

{% if offenders | length == 0 %}
select 'ok' as offender where false
{% else %}
    {% for offender in offenders %}
select '{{ offender }}' as offender
        {% if not loop.last %}union all{% endif %}
    {% endfor %}
{% endif %}
