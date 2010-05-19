-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> contacts_instances/main.drop.sql [BEGIN]

\i contacts_instances/c_phone.drop.sql
\i contacts_instances/c_fax.drop.sql
\i contacts_instances/c_postal.drop.sql
\i contacts_instances/c_person.drop.sql
\i contacts_instances/c_system_id.drop.sql
\i contacts_instances/c_email.drop.sql

\echo NOTICE >>>>> contacts_instances/main.drop.sql [END]