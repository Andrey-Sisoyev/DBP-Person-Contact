-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> contacts_instances/c_phone.drop.sql [BEGIN]

--------------------------------------------------------------------------
--------------------------------------------------------------------------

DROP FUNCTION IF EXISTS instaniate_contact_as_phone(par_contact_id integer, par_contact_phone_ci contact_phone_construction_input);

DROP TYPE IF EXISTS contact_phone_construction_input;

DROP TRIGGER IF EXISTS tri_personal_contacts_onmodify ON contacts__phones;
DROP TRIGGER IF EXISTS tri_personal_contacts_onderef  ON contacts__phones;

DROP INDEX IF EXISTS phones_of_contacts_idx;

DELETE FROM contacts__phones;
UPDATE contacts SET contact_type = NULL, contact_instaniated_isit = FALSE WHERE contact_type = code_id_of(TRUE, make_acodekeyl_bystr2('Personal contacts types', 'phone'));

DROP TABLE IF EXISTS contacts__phones;

SELECT remove_code(TRUE, make_acodekeyl_bystr2('Personal contacts types', 'phone'), TRUE, TRUE, TRUE);

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> contacts_instances/c_phone.drop.sql [END]
