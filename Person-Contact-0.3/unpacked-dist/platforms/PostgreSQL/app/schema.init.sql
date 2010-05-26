-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For information about license see COPYING file in the root directory of current nominal package

--------------------------------------------------------------------------
--------------------------------------------------------------------------

CREATE ROLE user_db<<$db_name$>>_app<<$app_name$>>_owner
   WITH LOGIN
        UNENCRYPTED PASSWORD 'user_db<<$db_name$>>_app<<$app_name$>>_owner';

CREATE ROLE user_db<<$db_name$>>_app<<$app_name$>>_data_admin
   WITH LOGIN
        UNENCRYPTED PASSWORD 'user_db<<$db_name$>>_app<<$app_name$>>_data_admin';

CREATE ROLE user_db<<$db_name$>>_app<<$app_name$>>_data_reader
   WITH LOGIN
        UNENCRYPTED PASSWORD 'user_db<<$db_name$>>_app<<$app_name$>>_data_reader';

\echo NOTICE: If syntax error on "IN DATABASE " is encountered here - it's about PostgreSQL new feature. In v9.0 they allowed "ALTER ROLE ... IN DATABASE ...". You are probably using older version.
\echo NOTICE: Don't worry about it.
ALTER ROLE user_db<<$db_name$>>_app<<$app_name$>>_owner       IN DATABASE <<$db_name$>> SET search_path TO sch_<<$app_name$>>, comn_funs, public;
ALTER ROLE user_db<<$db_name$>>_app<<$app_name$>>_data_admin  IN DATABASE <<$db_name$>> SET search_path TO sch_<<$app_name$>>, comn_funs, public;
ALTER ROLE user_db<<$db_name$>>_app<<$app_name$>>_data_reader IN DATABASE <<$db_name$>> SET search_path TO sch_<<$app_name$>>, comn_funs, public;

-- \/ to remove when migrate on PostgreSQL >= v9.0
ALTER ROLE user_db<<$db_name$>>_app<<$app_name$>>_owner       SET search_path TO sch_<<$app_name$>>, comn_funs, public;
ALTER ROLE user_db<<$db_name$>>_app<<$app_name$>>_data_admin  SET search_path TO sch_<<$app_name$>>, comn_funs, public;
ALTER ROLE user_db<<$db_name$>>_app<<$app_name$>>_data_reader SET search_path TO sch_<<$app_name$>>, comn_funs, public;


\! mkdir <<$PGDATA$>>pg_tblspc/<<$db_name$>>
\! mkdir <<$PGDATA$>>pg_tblspc/<<$db_name$>>/<<$app_name$>>
\! mkdir <<$PGDATA$>>pg_tblspc/<<$db_name$>>/<<$app_name$>>/tabsp.data
\! mkdir <<$PGDATA$>>pg_tblspc/<<$db_name$>>/<<$app_name$>>/tabsp_idxs.data

CREATE TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>
        OWNER user_db<<$db_name$>>_app<<$app_name$>>_owner
        LOCATION '<<$PGDATA$>>pg_tblspc/<<$db_name$>>/<<$app_name$>>/tabsp.data';

CREATE TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>_idxs
        OWNER user_db<<$db_name$>>_app<<$app_name$>>_owner
        LOCATION '<<$PGDATA$>>pg_tblspc/<<$db_name$>>/<<$app_name$>>/tabsp_idxs.data';

-------------------------
-- (1) case sensetive (2) postgres lowercases real names
\c <<$db_name$>> user_<<$db_name$>>_owner

GRANT CONNECT ON DATABASE <<$db_name$>> TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_owner, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.dbp_applications                   TO user_db<<$db_name$>>_app<<$app_name$>>_owner;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.dbp__db_dependant_clusterwide_objs TO user_db<<$db_name$>>_app<<$app_name$>>_owner;
GRANT EXECUTE ON FUNCTION public.register_cwobj_tobe_dependant_on_current_dbapp(
        par_cwobj_name              varchar
      , par_cwobj_type              t_clusterwide_obj_types
      , par_cwobj_additional_data_1 varchar
      , par_application_name        varchar
      , par_drop_it_by_cascade_when_dropping_db  boolean
      , par_drop_it_by_cascade_when_dropping_app boolean
      ) TO user_db<<$db_name$>>_app<<$app_name$>>_owner;
GRANT EXECUTE ON FUNCTION public.unregister_cwobj_thatwere_dependant_on_current_dbapp(
        par_cwobj_name varchar
      , par_cwobj_type t_clusterwide_obj_types
      ) TO user_db<<$db_name$>>_app<<$app_name$>>_owner;

INSERT INTO public.dbp_applications (application_name, dbp_standard_version) VALUES ('<<$app_name$>>', '<<$pkg.std_ver$>>');
SELECT public.register_cwobj_tobe_dependant_on_current_dbapp(
                'user_db<<$db_name$>>_app<<$app_name$>>_owner'
              , 'role'
              , NULL :: varchar
              , '<<$app_name$>>'
              , TRUE
              , TRUE
              ) AS owner_role_registered_as_dependant_clusterwide_obj
     , public.register_cwobj_tobe_dependant_on_current_dbapp(
                'user_db<<$db_name$>>_app<<$app_name$>>_data_admin'
              , 'role'
              , NULL :: varchar
              , '<<$app_name$>>'
              , TRUE
              , TRUE
              ) AS data_admin_role_registered_as_dependant_clusterwide_obj
     , public.register_cwobj_tobe_dependant_on_current_dbapp(
                'user_db<<$db_name$>>_app<<$app_name$>>_data_reader'
              , 'role'
              , NULL :: varchar
              , '<<$app_name$>>'
              , TRUE
              , TRUE
              ) AS data_reader_role_registered_as_dependant_clusterwide_obj
     , public.register_cwobj_tobe_dependant_on_current_dbapp(
                'tabsp_<<$db_name$>>_<<$app_name$>>'
              , 'tablespace'
              , '<<$PGDATA$>>pg_tblspc/<<$db_name$>>/<<$app_name$>>/tabsp.data'
              , '<<$app_name$>>'
              , TRUE
              , TRUE
              ) AS apptblspc_role_registered_as_dependant_clusterwide_obj
     , public.register_cwobj_tobe_dependant_on_current_dbapp(
                'tabsp_<<$db_name$>>_<<$app_name$>>_idxs'
              , 'tablespace'
              , '<<$PGDATA$>>pg_tblspc/<<$db_name$>>/<<$app_name$>>/tabsp_idxs.data'
              , '<<$app_name$>>'
              , TRUE
              , TRUE
              ) AS apptblspc_idxs_role_registered_as_dependant_clusterwide_obj;

-------------------------

CREATE SCHEMA sch_<<$app_name$>> AUTHORIZATION user_db<<$db_name$>>_app<<$app_name$>>_owner;

\c <<$db_name$>> user_db<<$db_name$>>_app<<$app_name$>>_owner
SET search_path TO sch_<<$app_name$>>, comn_funs, public;

GRANT USAGE ON SCHEMA sch_<<$app_name$>> TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;

CREATE TABLE sch_<<$app_name$>>.dbp_packages (
        package_name         varchar
      , package_version      varchar
      , dbp_standard_version varchar
) TABLESPACE tabsp_<<$db_name$>>_dflt;

--------------------------------------------------------
-- Service functions:

CREATE OR REPLACE FUNCTION enter_schema_namespace() RETURNS comn_funs.t_namespace_info
LANGUAGE plpgsql
AS $$
DECLARE r comn_funs.t_namespace_info;
BEGIN
        SELECT comn_funs.enter_schema_namespace('sch_<<$app_name$>>') INTO r;
        RETURN r;
END;
$$;

-----------

COMMENT ON FUNCTION enter_schema_namespace() IS
'=comn_funs.enter_schema_namespace(''sch_<<$app_name$>>'')

Usage pattern:
=====================================================
CREATE OR REPLACE FUNCTION <my_func>(<params>) RETURNS <return_type> LANGUAGE plpgsql AS $$
DECLARE
        <variables_declarations>
        namespace_info comn_funs.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        <function_body>

        PERFORM comn_funs.leave_schema_namespace(namespace_info);
        RETURN <return_value>;
END;
$$;
=====================================================
But dont forget, that often better style would be writing like this:
        CREATE OR REPLACE FUNCTION <my_func>(<params>) RETURNS <return_type> LANGUAGE plpgsql SET search_path TO <schema_name>, comn_funs, public AS $$ ... $$;
';

-----------

GRANT EXECUTE ON FUNCTION enter_schema_namespace()TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
