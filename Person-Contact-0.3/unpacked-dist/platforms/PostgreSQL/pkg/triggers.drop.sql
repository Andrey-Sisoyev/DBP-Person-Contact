-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> triggers.drop.sql [BEGIN]

DROP TRIGGER IF EXISTS tri_person_ondelete ON persons;
DROP FUNCTION IF EXISTS person_ondelete();

DROP TRIGGER IF EXISTS tri_personal_contacts_onmodify ON contacts;
DROP FUNCTION IF EXISTS personal_contacts_onmodify();

-- used for triggers by modules in contact_instances
DROP FUNCTION IF EXISTS personal_contact_detail_onderef();
DROP FUNCTION IF EXISTS personal_contact_detail_onmodify();

\echo NOTICE >>>>> triggers.drop.sql [END]