{#-
  Per-developer schema prefix for the dev target, from DBT_DEV_PREFIX:
    - local runs: export DBT_DEV_PREFIX=DEVONB
    - Snowflake-hosted runs: env.yml 'dev' environment (first name + last initial),
      overridable with ENV_VARS / --env-vars.
  Cleaned to an identifier: text before '@', non [A-Za-z0-9_] -> '_', uppercased.
-#}
{% macro dev_prefix() -%}
    {%- set raw = env_var('DBT_DEV_PREFIX', '') | trim -%}
    {%- if raw == '' -%}
        {{ exceptions.raise_compiler_error(
            "DBT_DEV_PREFIX is not set; the dev target needs it to name your schemas. "
            ~ "Locally: export DBT_DEV_PREFIX=<FIRSTNAME><LAST INITIAL>, e.g. DEVONB. "
            ~ "Snowflake-hosted: run with ENVIRONMENT = 'dev' or ENV_VARS = ('DBT_DEV_PREFIX' = '...').") }}
    {%- endif -%}
    {{ modules.re.sub('[^A-Za-z0-9_]', '_', raw.split('@')[0]) | upper }}
{%- endmacro %}
