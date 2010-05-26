-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> contacts_instances/main.init.sql [BEGIN]

\i contacts_instances/c_phone.init.sql
\i contacts_instances/c_fax.init.sql
\i contacts_instances/c_postal.init.sql
\i contacts_instances/c_person.init.sql
\i contacts_instances/c_system_id.init.sql
\i contacts_instances/c_email.init.sql

\echo NOTICE >>>>> contacts_instances/main.init.sql [END]