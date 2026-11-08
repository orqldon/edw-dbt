{#-
  Schema for a model under models/<TIER>/<SCHEMA>/...:
    - +schema config if set, else the <SCHEMA> folder name (node.fqn[2]);
    - dev target: prefixed with dev_prefix(), e.g. DEVONB_HCM;
    - other targets: unprefixed, e.g. HCM.
  A model placed directly in a tier folder (no schema folder) is an error.
  Nodes outside the tier folders (tests, seeds, ...) use the target's schema.
-#}
{% macro generate_schema_name(custom_schema_name=none, node=none) -%}
    {%- set in_tier = node is not none
          and node.resource_type == 'model'
          and node.config.database is not none -%}

    {%- if not in_tier -%}
        {{ (custom_schema_name or target.schema) | trim | upper }}
    {%- else -%}
        {%- if custom_schema_name is not none -%}
            {%- set base = custom_schema_name | trim -%}
        {%- elif node.fqn | length >= 4 -%}
            {%- set base = node.fqn[2] -%}
        {%- else -%}
            {{ exceptions.raise_compiler_error(
                "Model '" ~ node.name ~ "' sits directly in tier folder '" ~ node.fqn[1]
                ~ "'. Put it in a schema folder: models/" ~ node.fqn[1] ~ "/<SCHEMA>/" ~ node.name ~ ".sql") }}
        {%- endif -%}

        {%- if target.name | lower == 'dev' -%}
            {{ (dev_prefix() ~ '_' ~ base) | upper }}
        {%- else -%}
            {{ base | upper }}
        {%- endif -%}
    {%- endif -%}
{%- endmacro %}
