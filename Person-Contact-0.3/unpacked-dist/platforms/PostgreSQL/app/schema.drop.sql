-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For information about license see COPYING file in the root directory of current nominal package

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\! rm <<$PGDATA$>>db_<<$db_name$>>_app_<<$app_name$>>_drop_additional_routines__.sql

SELECT pg_catalog.pg_file_write(
                '<<$PGDATA$>>db_<<$db_name$>>_app_<<$app_name$>>_drop_additional_routines__.sql'
              ,    E'\nDROP TABLESPACE IF EXISTS ' || tbspc_name || ';'
                || E'\n\\! rm -rf  ' || tbspc_file
              , TRUE
              )
FROM dblink( 'dbname=<<$db_name$>>'
           , 'SELECT a.cwobj_name, a.cwobj_additional_data_1 '
           ||'FROM public.dbp__db_dependant_clusterwide_objs AS a '
           ||'WHERE cwobj_type = ''tablespace'' '
           ||'  AND a.drop_it_by_cascade_when_dropping_app '
           ||'  AND application_name = ''<<$app_name$>>'' '
           ) AS t(tbspc_name varchar, tbspc_file varchar);

SELECT pg_catalog.pg_file_write(
                '<<$PGDATA$>>db_<<$db_name$>>_app_<<$app_name$>>_drop_additional_routines__.sql'
              ,    E'\nREVOKE CONNECT ON DATABASE <<$db_name$>> FROM ' || role_name || ';'
                || E'\nDROP ROLE IF EXISTS ' || role_name || ';'
              , TRUE
              )
FROM dblink( 'dbname=<<$db_name$>>'
           , 'SELECT a.cwobj_name '
           ||'FROM public.dbp__db_dependant_clusterwide_objs AS a '
           ||'WHERE cwobj_type = ''role'' '
           ||'  AND a.drop_it_by_cascade_when_dropping_app '
           ||'  AND application_name = ''<<$app_name$>>'' '
           ) AS t(role_name varchar);

\c <<$db_name$>> user_<<$db_name$>>_owner
SET search_path TO comn_funs, public;

DELETE FROM dbp_applications WHERE application_name = '<<$app_name$>>'
                               AND dbp_standard_version = '<<$pkg.std_ver$>>';

DROP FUNCTION IF EXISTS sch_<<$app_name$>>.enter_schema_namespace();
DROP TABLE sch_<<$app_name$>>.dbp_packages;
DROP SCHEMA IF EXISTS sch_<<$app_name$>> CASCADE;

REVOKE ALL ON TABLE public.dbp_applications FROM user_db<<$db_name$>>_app<<$app_name$>>_owner;
REVOKE ALL ON TABLE public.dbp__db_dependant_clusterwide_objs FROM user_db<<$db_name$>>_app<<$app_name$>>_owner;
REVOKE ALL ON FUNCTION public.register_cwobj_tobe_dependant_on_current_dbapp(
        par_cwobj_name              varchar
      , par_cwobj_type              t_clusterwide_obj_types
      , par_cwobj_additional_data_1 varchar
      , par_application_name        varchar
      , par_drop_it_by_cascade_when_dropping_db  boolean
      , par_drop_it_by_cascade_when_dropping_app boolean
      ) FROM user_db<<$db_name$>>_app<<$app_name$>>_owner;
REVOKE ALL ON FUNCTION public.unregister_cwobj_thatwere_dependant_on_current_dbapp(
        par_cwobj_name varchar
      , par_cwobj_type t_clusterwide_obj_types
      ) FROM user_db<<$db_name$>>_app<<$app_name$>>_owner;

\c <<$db_name$>> user_<<$db_name$>>_owner

\set ECHO all
\i <<$PGDATA$>>db_<<$db_name$>>_app_<<$app_name$>>_drop_additional_routines__.sql
\set ECHO none

\! rm <<$PGDATA$>>db_<<$db_name$>>_app_<<$app_name$>>_drop_additional_routines__.sql