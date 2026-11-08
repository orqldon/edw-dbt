{#-
  Tier database: <TARGET>_<TIER>, e.g. TEST_T4_DATA_MART.
  <TIER> comes from +database in dbt_project.yml (one per tier folder).
  Nodes without a configured database use the target's default database.
-#}
{% macro generate_database_name(custom_database_name=none, node=none) -%}
    {%- if custom_database_name is none -%}
        {{ target.database }}
    {%- else -%}
        {{ (target.name ~ '_' ~ custom_database_name | trim) | upper }}
    {%- endif -%}
{%- endmacro %}
