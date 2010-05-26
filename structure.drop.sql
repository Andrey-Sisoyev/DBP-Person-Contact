-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\c <<$db_name$>> user_db<<$db_name$>>_app<<$app_name$>>_owner

SET search_path TO sch_<<$app_name$>>; -- , comn_funs, public; -- sets only for current session

DELETE FROM dbp_packages WHERE package_name = '<<$pkg.name$>>'
                           AND package_version = '<<$pkg.ver$>>'
                           AND dbp_standard_version = '<<$pkg.std_ver$>>';

-- IF DROPPING CUSTOM ROLES/TABLESPACES, then don't forget to unregister
-- them (under application owner DB account) using
-- FUNCTION public.unregister_cwobj_thatwere_dependant_on_current_dbapp(
--        par_cwobj_name varchar
--      , par_cwobj_type t_clusterwide_obj_types
--      )
-- , where TYPE public.t_clusterwide_obj_types IS ENUM ('tablespace', 'role')

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

\i ../data/data.drop.sql
\i functions.drop.sql
\i triggers.drop.sql

-------------------------------------------------------------------------------

\echo NOTICE >>>>> structure.drop.sql [BEGIN]

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

DROP INDEX IF EXISTS names_of_contacts_idx;
DROP TABLE IF EXISTS contacts_names;
SELECT remove_code(TRUE, make_acodekeyl_bystr2('Named entities', 'contact'), TRUE, TRUE, TRUE);

DROP INDEX IF EXISTS persons_of_contacts_idx;
DROP INDEX IF EXISTS types_of_contacts_idx;
DROP TABLE IF EXISTS contacts;
SELECT remove_code(TRUE, make_acodekeyl_bystr1('Personal contacts types'), TRUE, TRUE, TRUE);

DROP INDEX IF EXISTS names_of_persons_idx;
DROP TABLE IF EXISTS persons_names;
SELECT remove_code(TRUE, make_acodekeyl_bystr2('Named entities', 'person'), TRUE, TRUE, TRUE);

DROP TABLE IF EXISTS persons_languages;

DROP TABLE IF EXISTS persons;
SELECT remove_code(TRUE, make_acodekeyl_bystr1('Persons types'), TRUE, TRUE, TRUE);

DROP SEQUENCE IF EXISTS contacts_ids_seq;
DROP SEQUENCE IF EXISTS persons_ids_seq;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

\echo NOTICE >>>>> structure.drop.sql [END]