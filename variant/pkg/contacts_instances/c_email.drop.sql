-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo c_email.drop.sql

DROP FUNCTION IF EXISTS instaniate_contact_as_email(par_contact_id integer, par_contact_email_ci contact_email_construction_input);

DROP TYPE IF EXISTS contact_email_construction_input;

DROP TRIGGER IF EXISTS tri_personal_contacts_onmodify ON contacts__emails;
DROP TRIGGER IF EXISTS tri_personal_contacts_onderef  ON contacts__emails;

DROP INDEX IF EXISTS emails_of_contacts_idx;

DELETE FROM contacts__emails;
UPDATE contacts SET contact_type = NULL, contact_instaniated_isit = FALSE WHERE contact_type = code_id_of(TRUE, make_acodekeyl_bystr2('Personal contacts types', 'e-mail'));

DROP TABLE IF EXISTS contacts__emails;

SELECT remove_code(TRUE, make_acodekeyl_bystr2('Personal contacts types', 'e-mail'), TRUE, TRUE, TRUE);
