-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo c_system_id.drop.sql

DROP FUNCTION IF EXISTS instaniate_contact_as_system_id(par_contact_id integer, par_contact_system_id_ci contact_system_id_construction_input);

DROP TYPE IF EXISTS contact_system_id_construction_input;

DROP TRIGGER IF EXISTS tri_personal_contacts_onmodify ON contacts__systems_ids;
DROP TRIGGER IF EXISTS tri_personal_contacts_onderef  ON contacts__systems_ids;

DROP INDEX IF EXISTS nicks_of_contacts_idx;
DROP INDEX IF EXISTS sysnicks_of_contacts_idx;

DELETE FROM contacts__systems_ids;
UPDATE contacts SET contact_type = NULL, contact_instaniated_isit = FALSE WHERE contact_type = code_id_of(TRUE, make_acodekeyl_bystr2('Personal contacts types', 'ID in some system'));

DROP TABLE IF EXISTS contacts__systems_ids;


SELECT remove_code(TRUE, make_acodekeyl_bystr2('Personal contacts types', 'ID in some system'), TRUE, TRUE, TRUE);
SELECT remove_code(TRUE, make_acodekeyl_bystr1('Persons registering systems'), TRUE, TRUE, TRUE);
