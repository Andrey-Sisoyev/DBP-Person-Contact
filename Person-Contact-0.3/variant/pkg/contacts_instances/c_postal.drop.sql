-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> contacts_instances/c_postal.drop.sql [BEGIN]

--------------------------------------------------------------------------
--------------------------------------------------------------------------

DROP FUNCTION IF EXISTS instaniate_contact_as_postal(par_contact_id integer, par_contact_postal_ci contact_postal_construction_input);
DROP FUNCTION IF EXISTS new_postal_address(par_postal_address_ci postal_address_construction_input);

DROP TYPE IF EXISTS contact_postal_construction_input;
DROP TYPE IF EXISTS postal_address_construction_input;

DROP TRIGGER IF EXISTS tri_personal_contacts_onmodify ON contacts__postal;
DROP TRIGGER IF EXISTS tri_personal_contacts_onderef  ON contacts__postal;

DELETE FROM contacts__postal;
UPDATE contacts SET contact_type = NULL, contact_instaniated_isit = FALSE WHERE contact_type = code_id_of(TRUE, make_acodekeyl_bystr2('Personal contacts types', 'postal'));

DROP TABLE IF EXISTS contacts__postal;
DROP TABLE IF EXISTS postal_addresses_in_languages;
DROP TABLE IF EXISTS postal_addresses;

DROP SEQUENCE IF EXISTS postal_addresses_ids_seq;

SELECT remove_code(TRUE, make_acodekeyl_bystr2('Personal contacts types', 'postal'), TRUE, TRUE, TRUE);

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> contacts_instances/c_postal.drop.sql [END]
