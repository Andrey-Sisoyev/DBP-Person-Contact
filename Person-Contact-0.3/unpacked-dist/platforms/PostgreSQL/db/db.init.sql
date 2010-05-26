-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For information about license see COPYING file in the root directory of current nominal package

--------------------------------------------------------------------------
--------------------------------------------------------------------------

CREATE ROLE user_<<$db_name$>>_owner
   WITH SUPERUSER
        NOCREATEDB
        LOGIN
        CREATEROLE
        UNENCRYPTED PASSWORD 'db_owner_password';

\! mkdir <<$PGDATA$>>pg_tblspc/<<$db_name$>>
\! mkdir <<$PGDATA$>>pg_tblspc/<<$db_name$>>/default.data

CREATE TABLESPACE tabsp_<<$db_name$>>_dflt
   OWNER user_<<$db_name$>>_owner
   LOCATION '<<$PGDATA$>>pg_tblspc/<<$db_name$>>/default.data';

-------------------------

CREATE DATABASE <<$db_name$>>
  WITH OWNER = user_<<$db_name$>>_owner
       ENCODING = 'UTF8'
       TABLESPACE = tabsp_<<$db_name$>>_dflt;

-------------------------
-- (1) case sensetive (2) postgres lowercases real names
\c <<$db_name$>>

CREATE LANGUAGE plpgsql;

-------------------------
-------------------------

CREATE TABLE public.dbp_applications (
        application_name     varchar PRIMARY KEY
      , dbp_standard_version varchar
) TABLESPACE tabsp_<<$db_name$>>_dflt;

COMMENT ON TABLE public.dbp_applications IS 'What applications initiated by DBP packaging standard are there in this data base.';

-------------------------

CREATE OR REPLACE FUNCTION public.version_of_standard_based_on_which_the_db_was_created() RETURNS varchar
LANGUAGE plpgsql AS $$
BEGIN
        RETURN '<<$pkg.std_ver$>>';
END;
$$;

-------------------------
-------------------------

CREATE TYPE public.t_clusterwide_obj_types AS ENUM ('tablespace', 'role');
CREATE TABLE public.dbp__db_dependant_clusterwide_objs (
        cwobj_name       varchar NOT NULL
      , cwobj_type       t_clusterwide_obj_types NOT NULL
      , cwobj_additional_data_1 varchar CHECK (cwobj_additional_data_1 IS NOT NULL OR cwobj_type != 'tablespace')
      , application_name varchar REFERENCES dbp_applications(application_name) ON UPDATE CASCADE ON DELETE CASCADE
      , drop_it_by_cascade_when_dropping_db  boolean NOT NULL
      , drop_it_by_cascade_when_dropping_app boolean     NULL CHECK (drop_it_by_cascade_when_dropping_app IS NOT NULL OR application_name IS NULL)
      , PRIMARY KEY(cwobj_name, cwobj_type)
) TABLESPACE tabsp_<<$db_name$>>_dflt;

-------------------------

COMMENT ON TABLE public.dbp__db_dependant_clusterwide_objs IS
'What roles, tablespaces or whatever else clusterwide objects (whose types are enumerated by "t_clusterwide_obj_types" type) are there created for use ONLY with this database/application.
Main use is in initiation/dropping cycle performed by DBP packaging framework. Whenever application is dropped, it means, that some schema will go down, but roles and tablespaces are never dropped by cascad. With help of this table and som procedures "now they are"!
Field "drop_it_by_cascade_when_dropping_db"  is speaking for itself (by "dropping" here is meant dropping performed by DBP packaging framework).
Field "drop_it_by_cascade_when_dropping_app" is speaking for itself (by "dropping" here is meant dropping performed by DBP packaging framework).
Field "drop_it_by_cascade_when_dropping_app" allowed to contain NULL only when field "application_name" contains NULL.
If application name is NULL, then cluster wide object is dependant only from current database (not dependant on any application).
For case, when "cwobj_type" is tablespace, "cwobj_additional_data_1" must conain path to tablespace directory file.
';

-------------------------

CREATE OR REPLACE FUNCTION public.register_cwobj_tobe_dependant_on_current_dbapp(
        par_cwobj_name              varchar
      , par_cwobj_type              t_clusterwide_obj_types
      , par_cwobj_additional_data_1 varchar
      , par_application_name        varchar
      , par_drop_it_by_cascade_when_dropping_db  boolean
      , par_drop_it_by_cascade_when_dropping_app boolean
      ) RETURNS integer
LANGUAGE plpgsql
AS $$
BEGIN
        INSERT INTO public.dbp__db_dependant_clusterwide_objs(
                 cwobj_name
               , cwobj_type
               , cwobj_additional_data_1
               , application_name
               , drop_it_by_cascade_when_dropping_db
               , drop_it_by_cascade_when_dropping_app
               )
        VALUES ( par_cwobj_name
               , par_cwobj_type
               , par_cwobj_additional_data_1
               , par_application_name
               , par_drop_it_by_cascade_when_dropping_db
               , par_drop_it_by_cascade_when_dropping_app
               );
        RETURN 1;
END;
$$;

-------------------------

CREATE OR REPLACE FUNCTION public.unregister_cwobj_thatwere_dependant_on_current_dbapp(
        par_cwobj_name varchar
      , par_cwobj_type t_clusterwide_obj_types
      ) RETURNS integer
LANGUAGE plpgsql
AS $$
BEGIN   DELETE FROM public.dbp__db_dependant_clusterwide_objs
        WHERE ROW(cwobj_name, par_cwobj_type) = ROW(par_cwobj_name, par_cwobj_type);
        RETURN 1;
END;
$$;

---------------------------------------------------------------------------
---------------------------------------------------------------------------

SELECT public.register_cwobj_tobe_dependant_on_current_dbapp(
                'user_<<$db_name$>>_owner'
              , 'role'
              , NULL :: varchar
              , NULL :: varchar
              , TRUE
              , NULL :: boolean
              )
     , public.register_cwobj_tobe_dependant_on_current_dbapp(
                'tabsp_<<$db_name$>>_dflt'
              , 'tablespace'
              , '<<$PGDATA$>>pg_tblspc/<<$db_name$>>/default.data'
              , NULL :: varchar
              , TRUE
              , NULL :: boolean
              );

---------------------------------------------------------------------------
---------------------------------------------------------------------------

REVOKE ALL ON TABLE public.dbp_applications FROM PUBLIC;
REVOKE ALL ON TABLE public.dbp__db_dependant_clusterwide_objs FROM PUBLIC;
REVOKE ALL ON FUNCTION public.register_cwobj_tobe_dependant_on_current_dbapp(
        par_cwobj_name              varchar
      , par_cwobj_type              t_clusterwide_obj_types
      , par_cwobj_additional_data_1 varchar
      , par_application_name        varchar
      , par_drop_it_by_cascade_when_dropping_db  boolean
      , par_drop_it_by_cascade_when_dropping_app boolean
      ) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.unregister_cwobj_thatwere_dependant_on_current_dbapp(
        par_cwobj_name varchar
      , par_cwobj_type t_clusterwide_obj_types
      ) FROM PUBLIC;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.dbp_applications                   TO user_<<$db_name$>>_owner;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.dbp__db_dependant_clusterwide_objs TO user_<<$db_name$>>_owner;
GRANT EXECUTE ON FUNCTION public.register_cwobj_tobe_dependant_on_current_dbapp(
        par_cwobj_name              varchar
      , par_cwobj_type              t_clusterwide_obj_types
      , par_cwobj_additional_data_1 varchar
      , par_application_name        varchar
      , par_drop_it_by_cascade_when_dropping_db  boolean
      , par_drop_it_by_cascade_when_dropping_app boolean
      ) TO user_<<$db_name$>>_owner;
GRANT EXECUTE ON FUNCTION public.unregister_cwobj_thatwere_dependant_on_current_dbapp(
        par_cwobj_name varchar
      , par_cwobj_type t_clusterwide_obj_types
      ) TO user_<<$db_name$>>_owner;

