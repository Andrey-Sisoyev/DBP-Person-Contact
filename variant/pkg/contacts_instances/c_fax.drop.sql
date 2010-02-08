-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo c_fax.drop.sql

DROP FUNCTION IF EXISTS instaniate_contact_as_fax(par_contact_id integer, par_contact_fax_ci contact_fax_construction_input);

DROP TYPE IF EXISTS contact_fax_construction_input;

DROP TRIGGER IF EXISTS tri_personal_contacts_onmodify ON contacts__faxes;
DROP TRIGGER IF EXISTS tri_personal_contacts_onderef  ON contacts__faxes;

DROP INDEX IF EXISTS faxes_of_contacts_idx;

DELETE FROM contacts__faxes;
UPDATE contacts SET contact_type = NULL, contact_instaniated_isit = FALSE WHERE contact_type = code_id_of(TRUE, make_acodekeyl_bystr2('Personal contacts types', 'fax'));

DROP TABLE IF EXISTS contacts__faxes;

SELECT remove_code(TRUE, make_acodekeyl_bystr2('Personal contacts types', 'fax'), TRUE, TRUE, TRUE);
