# EDW dbt project

A dbt project that builds EDW models into the tier databases (`<ENV>_T3_INTEGRATION`, `<ENV>_T4_DATA_MART`, ...). The folder a model sits in decides its database and schema, and the selected target decides the environment (`DEV`, `TEST`, `UAT`, `PROD`). In DEV, each developer gets their own copy of every schema.

## Where models land

```
models/<TIER>/<SCHEMA>/<model>.sql  ->  <ENV>_<TIER>.<SCHEMA>.<MODEL>        (test, uat, prod)
                                    ->  DEV_<TIER>.<PREFIX>_<SCHEMA>.<MODEL>  (dev)
```

| Target | `models/T4_DATA_MART/TASTY_BYTES/dim_truck.sql` builds to |
|---|---|
| `dev` | `DEV_T4_DATA_MART.DEVONB_TASTY_BYTES.DIM_TRUCK` |
| `test` | `TEST_T4_DATA_MART.TASTY_BYTES.DIM_TRUCK` |
| `uat` | `UAT_T4_DATA_MART.TASTY_BYTES.DIM_TRUCK` |
| `prod` | `PROD_T4_DATA_MART.TASTY_BYTES.DIM_TRUCK` |

Tier folders and their default materializations:

| Folder | Database | Default |
|---|---|---|
| `T3_REFERENCE` | `<ENV>_T3_REFERENCE` | view |
| `T3_INTEGRATION` | `<ENV>_T3_INTEGRATION` | view |
| `T4_DATA_MART` | `<ENV>_T4_DATA_MART` | table |
| `T5_PRESENTATION` | `<ENV>_T5_PRESENTATION` | view |

T1 and T2 are loaded outside dbt, so they are declared as sources (`models/sources/_sources.yml`), not built as models. Sources take their database from the target (`<ENV>_T2_PERSISTENT_STAGING`) and get no DEV prefix.

The example models are a small Tasty Bytes star schema (`TASTY_BYTES` schema in each tier); [WALKTHROUGH.md](WALKTHROUGH.md) explains them. Their raw data is cloned into every T2 database by [setup/clone_tasty_bytes.sql](setup/clone_tasty_bytes.sql), run once as ACCOUNTADMIN.

What goes in which tier:
- **T3_INTEGRATION:** interim processing: joins, deduplication, type fixes, filters. Only when there is real work to do; a T4 model may read a clean source directly.
- **T4_DATA_MART:** dimensions and facts, persisted as tables and tested.
- **T5_PRESENTATION:** what consumers query: pass-through views over each T4 model plus aggregates.

The Tasty Bytes models read only the orders from `tasty_bytes_order_start_date` onward (a project var in `dbt_project.yml`, default one month). Override it per run with `--vars '{tasty_bytes_order_start_date: "2022-01-01"}'`.

Rules:
- Every model must be in a schema folder. A model placed directly in a tier folder fails to compile, with a message saying where to move it.
- Folders below the schema folder are only for organisation: `models/T3_INTEGRATION/HCM/staging/x.sql` still builds in `HCM`.
- `+schema` on a model or folder overrides the folder name. The DEV prefix is still applied.

## How the configuration files fit together

| File | Read by | Purpose |
|---|---|---|
| `dbt_project.yml` | all dbt | Maps each tier folder to its tier (`+database`) and sets materialization defaults. Children inherit and can override, per schema folder or per model. |
| `dbt_projects_profiles.yml` | dbt Projects on Snowflake only | Targets `dev`/`test`/`uat`/`prod`, each with a role, warehouse and default database. **The target is the environment switch.** It holds no credentials: hosted runs use the caller's session. |
| `~/.dbt/profiles.yml` | local dbt only | The same targets, plus connection and authentication details for each developer. Not in the repo. |
| `env.yml` | dbt Projects on Snowflake only | Snowflake runs its `{{ select ... }}` SQL before dbt starts and passes the results to dbt as `DBT_*` environment variables. Here it supplies only `DBT_DEV_PREFIX`. Choose its environment with `ENVIRONMENT` / `--env`, using the same name as the target. |
| `macros/generate_database_name.sql` | dbt | `<TARGET>_<TIER>`, uppercased. |
| `macros/generate_schema_name.sql` | dbt | Schema from the folder (or `+schema`). Under `dev`, prefixed with the developer's prefix. |
| `macros/dev_prefix.sql` | dbt | Reads `DBT_DEV_PREFIX` and cleans it: keeps the text before any `@`, replaces any character outside `[A-Za-z0-9_]` with `_`, and uppercases it. Fails under `dev` if unset. |
| `packages.yml` | dbt | Third-party packages, pinned to exact versions. `dbt deps` installs them into `dbt_packages/` and records the resolved versions in `package-lock.yml`. |
| `dbt_packages/` | dbt | The installed packages, **committed to git**. Snowflake can't download packages without an external access integration, and dbt skips `dbt deps` when this folder exists. |
| `.sqlfluff`, `.sqlfluffignore` | `dbt lint`, `dbt format` | SQL style rules (uppercase keywords, lowercase identifiers, 120-character lines, plus dbt's own rules) and the paths they skip. |

Two settings share the word "environment": the **target** (`--target`, from the profile) and the **env.yml environment** (`ENVIRONMENT` / `--env`). The target decides where things build. The env.yml environment only decides which variables are set. Always pass matching names.

## DEV prefix

Each developer's DEV schemas are named `<PREFIX>_<SCHEMA>`, for example `DEVONB_HCM`, so people working in parallel don't overwrite each other.

| Where you run | Prefix comes from |
|---|---|
| Local dbt | `export DBT_DEV_PREFIX=DEVONB` (put it in your shell profile) |
| Snowflake-hosted (Workspaces, deployed object) | `env.yml` reads `DEV_T3_INTEGRATION.DBT.DEV_PREFIX`: first name plus last-name initial from your Snowflake user, falling back to your user name |
| Either, one-off | Hosted: `ENV_VARS = ('DBT_DEV_PREFIX' = '...')`. Local: the shell variable. |

`DEV_PREFIX` is a secure view, owned by ACCOUNTADMIN because it reads `SNOWFLAKE.ACCOUNT_USAGE.USERS`, and returns only the caller's row. `ACCOUNT_USAGE` can lag up to about 2 hours for a newly created user, so a brand-new user gets the fallback until it catches up.

```sql
USE ROLE ACCOUNTADMIN;
CREATE OR REPLACE SECURE VIEW DEV_T3_INTEGRATION.DBT.DEV_PREFIX AS
SELECT COALESCE(
         (SELECT NULLIF(REGEXP_REPLACE(UPPER(TRIM(first_name) || LEFT(TRIM(last_name), 1)), '[^A-Z0-9_]', ''), '')
            FROM SNOWFLAKE.ACCOUNT_USAGE.USERS
           WHERE name = CURRENT_USER() AND deleted_on IS NULL
           LIMIT 1),
         REGEXP_REPLACE(UPPER(SPLIT_PART(CURRENT_USER(), '@', 1)), '[^A-Z0-9_]', '_')
       )::VARCHAR AS prefix;
GRANT SELECT ON VIEW DEV_T3_INTEGRATION.DBT.DEV_PREFIX TO ROLE SYSADMIN;
```

Two caveats:
- **Upstream models.** In DEV, `ref()` points to *your* copies, so build upstream models too: `dbt build --select +my_model`. Comparing against TEST/PROD state with `--defer` would remove this need, but it isn't set up yet.
- **Leftover schemas.** DEV accumulates one schema per developer per schema folder, and nothing removes them yet.

## Running

### Local

One-time setup: install dbt 2.x (`dbt system update` upgrades an existing install), add an `edw` profile to `~/.dbt/profiles.yml` with the four targets (same role, warehouse and database as `dbt_projects_profiles.yml`, plus your account, user and authentication), and export `DBT_DEV_PREFIX`.

```bash
cd dbt
dbt debug                       # connection check
dbt build                       # dev (default target)
dbt build --target test
dbt compile --target prod       # check names without building
dbt lint                        # SQL style; dbt lint --fix applies the auto-fixable ones
dbt format                      # rewrite layout in place; --check only reports
dbt check --vars '{run_project_evaluator: true}'   # best-practice checks (off by default)
```

`fct_order_line` is incremental: a normal build adds only new order lines. Rebuild it from scratch with `dbt build --full-refresh --select fct_order_line+`, which is needed after changing its logic or widening `tasty_bytes_order_start_date`.

### Snowflake-hosted (deployed project object)

The deployed object is `DEV_T3_INTEGRATION.DBT.EDW` (runtime 2.0.0, default target and environment `dev`). It is deployed from a Git-backed Snowsight workspace that holds this folder at its root (in this sandbox, workspace `edw-dbt`).

Redeploy after changing files:
1. Commit and push the changes, including `dbt_packages/` and `package-lock.yml` if packages changed.
2. In the Snowsight workspace, **Pull**.
3. Deploy the workspace's files to the project object:

```sql
ALTER DBT PROJECT DEV_T3_INTEGRATION.DBT.EDW
  DEPLOY FROM 'snow://workspace/USER$DEVONCOCO.PUBLIC."edw-dbt"/versions/live/';
```

The path is your user's workspace (`USER$<user>.PUBLIC."<workspace>"`).

Run:

```sql
EXECUTE DBT PROJECT DEV_T3_INTEGRATION.DBT.EDW ARGS = 'build --target dev'  ENVIRONMENT = 'dev';
EXECUTE DBT PROJECT DEV_T3_INTEGRATION.DBT.EDW ARGS = 'build --target test' ENVIRONMENT = 'test';
EXECUTE DBT PROJECT DEV_T3_INTEGRATION.DBT.EDW ARGS = 'build --target dev'  ENVIRONMENT = 'dev'
  ENV_VARS = ('DBT_DEV_PREFIX' = 'MYPREFIX');
```

## Adding things

- **A schema:** create `models/<TIER>/<SCHEMA>/`. dbt creates the schema on the first build.
- **A schema-level default:** nest it under the tier in `dbt_project.yml`:
  ```yaml
  T4_DATA_MART:
    TASTY_BYTES:
      +materialized: incremental
  ```
- **A source:** add it to `models/sources/_sources.yml` with `database: "{{ target.name | upper }}_T2_PERSISTENT_STAGING"`. The naming macros don't apply to sources.
- **Removing a model:** dbt doesn't drop the objects of deleted models. Drop them yourself in every environment.
- **A package:** add it to `packages.yml` with an exact version whose `require-dbt-version` includes 2.0 (see hub.getdbt.com), run `dbt deps`, and commit `packages.yml`, `package-lock.yml` and `dbt_packages/`.

## Notes for porting to an account with a stricter RBAC model

These worked here because SYSADMIN owns everything. Check each one before relying on it elsewhere.

- **Schema creation.** dbt runs `CREATE SCHEMA IF NOT EXISTS` for any schema it can't find. If schemas must come from a provisioning procedure, provision them first. To make a missing schema an error instead, override the `create_schema` macro to raise one.
- **Object ownership.** dbt rebuilds views and tables with `CREATE OR REPLACE`, which needs ownership of the existing object. If future-ownership grants give objects to a per-schema owner role, the dbt role must hold every such owner role.
- **One role, every tier.** A single run writes T3, T4 and T5 as one role, so that role needs write access to every tier it builds.
- **DEV per-user schemas.** Developers need `CREATE SCHEMA` on the DEV tier databases.
- **Project object and `DEV_PREFIX`.** Decide which schema holds the dbt project object and the prefix view, and who owns them. The view's owner needs `SNOWFLAKE.SECURITY_VIEWER` (or ACCOUNTADMIN). Update the view's name in `env.yml` to match.
- **Profiles.** Replace SYSADMIN / COMPUTE_WH in `dbt_projects_profiles.yml` with each environment's role and warehouse.
- **Versions.** Check `SELECT SYSTEM$SUPPORTED_DBT_VERSIONS();` lists `2.0.0`. A workspace defaults to the account's `DEFAULT_DBT_VERSION`; set it to 2.0.0, because the test syntax here (`arguments:`) needs dbt v2. `dbt check` needs a release build of dbt v2 locally; the 2.0.0 previews don't have it.
- **Packages without network access.** The work account likely has no external access integration either, so keep `dbt_packages/` committed. If one is added later, Snowflake can run `dbt deps` itself and the folder can go back into `.gitignore`.
