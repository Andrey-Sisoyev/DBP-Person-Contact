-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo c_person.drop.sql

DROP FUNCTION IF EXISTS instaniate_contact_as_person(par_contact_id integer, par_contact_person_ci contact_person_construction_input);

DROP TYPE IF EXISTS contact_person_construction_input;

DROP TRIGGER IF EXISTS tri_personal_contacts_onmodify ON contacts__persons;
DROP TRIGGER IF EXISTS tri_personal_contacts_onderef  ON contacts__persons;

DROP INDEX IF EXISTS representative_persons_of_contacts_idx;

DELETE FROM contacts__persons;
UPDATE contacts SET contact_type = NULL, contact_instaniated_isit = FALSE WHERE contact_type = code_id_of(TRUE, make_acodekeyl_bystr2('Personal contacts types', 'another person'));

DROP TABLE IF EXISTS contacts__persons;

SELECT remove_code(TRUE, make_acodekeyl_bystr2('Personal contacts types', 'another person'), TRUE, TRUE, TRUE);

