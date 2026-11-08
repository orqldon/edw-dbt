# dbt setup to-do

## Block dbt from creating schemas outside DEV

Schemas in TEST/UAT/PROD should be created by the provisioning procedure, which also sets up access privileges, not by dbt. Today dbt creates any missing schema on the first build. Override the adapter's schema-creation macro so that dbt stops with a pointer to the procedure instead.

Fill in from the work account:

- Procedure: `<DB>.<SCHEMA>.<PROC_NAME>`
- Arguments: `<ARGS>`, for example `('<database>', '<schema>', ...)`

```sql
-- macros/create_schema.sql
{% macro snowflake__create_schema(relation) -%}
  {%- if target.name == 'dev' -%}
    {# per-developer schemas still auto-create #}
    {%- call statement('create_schema') -%}
      create schema if not exists {{ relation.without_identifier() }}
    {%- endcall -%}
  {%- else -%}
    {{ exceptions.raise_compiler_error(
         relation.database ~ "." ~ relation.schema ~ " doesn't exist. Provision it with: "
         ~ "CALL <DB>.<SCHEMA>.<PROC_NAME>('" ~ relation.database ~ "', '" ~ relation.schema ~ "', <ARGS>); then rerun."
    ) }}
  {%- endif -%}
{%- endmacro %}
```

Before relying on it:

- Check that the DEV branch still matches dbt-snowflake's own `snowflake__create_schema` body on the current runtime.
- Check that the override takes effect on runtime 2.0.0 (dbt v2), both locally and with the hosted object. Test it by selecting a model whose schema doesn't exist under `--target test`.
- Revoke `CREATE SCHEMA` on the TEST/UAT/PROD tier databases from the dbt roles, so that a run can't create a schema even if it bypasses the macro.
- Update the README line "dbt creates the schema on the first build" (under "Adding things").
