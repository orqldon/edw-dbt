-- Loads Tasty Bytes raw data into <ENV>_T2_PERSISTENT_STAGING.TASTY_BYTES for every
-- environment, as zero-copy clones of the quickstart's base tables. Run once, outside dbt.
-- dbt then reads these tables as sources (models/sources/_sources.yml).
--
-- Clones share storage with the source until either side changes, so this costs nothing
-- up front. Re-running replaces the clones (CREATE OR REPLACE).
--
-- ACCOUNTADMIN because the source tables are ACCOUNTADMIN-owned; ownership of the copies
-- is then handed to SYSADMIN, the role dbt runs as.

USE ROLE ACCOUNTADMIN;

EXECUTE IMMEDIATE $$
DECLARE
    envs   ARRAY := ['DEV', 'TEST', 'UAT', 'PROD'];
    tables ARRAY := ['COUNTRY', 'FRANCHISE', 'LOCATION', 'MENU', 'TRUCK',
                     'CUSTOMER_LOYALTY', 'ORDER_HEADER', 'ORDER_DETAIL'];
    sch    VARCHAR;
    src    VARCHAR;
    tgt    VARCHAR;
BEGIN
    FOR e IN 0 TO ARRAY_SIZE(envs) - 1 DO
        sch := envs[e] || '_T2_PERSISTENT_STAGING.TASTY_BYTES';
        CREATE SCHEMA IF NOT EXISTS IDENTIFIER(:sch);

        FOR t IN 0 TO ARRAY_SIZE(tables) - 1 DO
            src := 'TASTY_BYTES_DBT_DB.DEV.' || tables[t];
            tgt := sch || '.' || tables[t];
            CREATE OR REPLACE TABLE IDENTIFIER(:tgt) CLONE IDENTIFIER(:src);
        END FOR;

        GRANT OWNERSHIP ON SCHEMA IDENTIFIER(:sch) TO ROLE SYSADMIN COPY CURRENT GRANTS;
        GRANT OWNERSHIP ON ALL TABLES IN SCHEMA IDENTIFIER(:sch) TO ROLE SYSADMIN COPY CURRENT GRANTS;
    END FOR;
    RETURN 'Cloned ' || ARRAY_SIZE(tables) || ' tables into ' || ARRAY_SIZE(envs) || ' environments';
END;
$$;
