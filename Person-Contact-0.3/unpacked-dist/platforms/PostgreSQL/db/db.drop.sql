-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For information about license see COPYING file in the root directory of current nominal package

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\! rm <<$PGDATA$>>db_<<$db_name$>>_drop_additional_routines__.sql

SELECT pg_catalog.pg_file_write(
                '<<$PGDATA$>>db_<<$db_name$>>_drop_additional_routines__.sql'
              ,    E'\nDROP TABLESPACE IF EXISTS ' || tbspc_name || ';'
                || E'\n\\! rm -rf  ' || tbspc_file
              , TRUE
              )
FROM dblink( 'dbname=<<$db_name$>>'
           , 'SELECT a.cwobj_name, a.cwobj_additional_data_1 '
           ||'FROM public.dbp__db_dependant_clusterwide_objs AS a '
           ||'WHERE cwobj_type = ''tablespace'' '
           ||  'AND a.drop_it_by_cascade_when_dropping_db'
           ) AS t(tbspc_name varchar, tbspc_file varchar);

SELECT pg_catalog.pg_file_write(
                '<<$PGDATA$>>db_<<$db_name$>>_drop_additional_routines__.sql'
              , E'\nDROP ROLE IF EXISTS ' || role_name || ';'
              , TRUE
              )
FROM dblink( 'dbname=<<$db_name$>>'
           , 'SELECT a.cwobj_name '
           ||'FROM public.dbp__db_dependant_clusterwide_objs AS a '
           ||'WHERE cwobj_type = ''role'' '
           ||  'AND a.drop_it_by_cascade_when_dropping_db'
           ) AS t(role_name varchar);

DROP DATABASE IF EXISTS <<$db_name$>>;

\set ECHO all
\i <<$PGDATA$>>db_<<$db_name$>>_drop_additional_routines__.sql
\set ECHO none

\! rm <<$PGDATA$>>db_<<$db_name$>>_drop_additional_routines__.sql