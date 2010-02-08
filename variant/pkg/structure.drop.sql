-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\i functions.drop.sql

\c <<$db_name$>> user_<<$app_name$>>_owner
\set ECHO queries

SET search_path TO sch_<<$app_name$>>, public; -- sets only for current session

DELETE FROM dbp_packages WHERE package_name = '<<$pkg.name$>>'
                           AND package_version = '<<$pkg.ver$>>'
                           AND dbp_standard_version = '<<$pkg.std_ver$>>';

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

DROP TRIGGER IF EXISTS tri_personal_contacts_onmodify ON contacts;

DROP FUNCTION IF EXISTS personal_contact_detail_onderef();
DROP FUNCTION IF EXISTS personal_contact_detail_onmodify();
DROP FUNCTION IF EXISTS personal_contacts_onmodify();

DROP INDEX IF EXISTS names_of_contacts_idx;
DROP TABLE IF EXISTS contacts_names;
SELECT remove_code(TRUE, make_acodekeyl_bystr2('Entities', 'contact'), TRUE, TRUE, TRUE);

DROP INDEX IF EXISTS persons_of_contacts_idx;
DROP INDEX IF EXISTS types_of_contacts_idx;
DROP TABLE IF EXISTS contacts;
SELECT remove_code(TRUE, make_acodekeyl_bystr1('Personal contacts types'), TRUE, TRUE, TRUE);

DROP INDEX IF EXISTS names_of_persons_idx;
DROP TABLE IF EXISTS persons_names;
SELECT remove_code(TRUE, make_acodekeyl_bystr2('Entities', 'person'), TRUE, TRUE, TRUE);

DROP TABLE IF EXISTS persons_languages;

DROP TABLE IF EXISTS persons;
SELECT remove_code(TRUE, make_acodekeyl_bystr1('Persons types'), TRUE, TRUE, TRUE);

DROP SEQUENCE IF EXISTS contacts_ids_seq;
DROP SEQUENCE IF EXISTS persons_ids_seq;

