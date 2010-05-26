-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\c <<$db_name$>> user_db<<$db_name$>>_app<<$app_name$>>_owner

SET search_path TO sch_<<$app_name$>>, comn_funs, public;
SELECT set_config('client_min_messages', 'NOTICE', FALSE);

\echo NOTICE >>>>>> tests.sql [BEGIN]
\echo WARNING!!! This tester is not guaranteed to be safe for user data (if not said otherwise in package info file) - do not apply it where user already defined it's codes!!

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo --------------------------------------------------------------
\echo NOTICE >>>>>> Just in case... if anything is lost, at least one will be able to recover it from log...

SELECT * FROM persons;
SELECT * FROM contacts;
SELECT * FROM contacts__emails;

\echo
\echo --------------------------------------------------------------
\echo

\i tests.prepare.sql

\echo
\echo --------------------------------------------------------------
\echo NOTICE >>>>>> Test data inserted in DB - observe it:

SELECT * FROM persons;
SELECT * FROM contacts;
SELECT * FROM contacts__emails;

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo
\echo --------------------------------------------------------------
\echo NOTICE >>>>>> Testing functions

\c <<$db_name$>> user_db<<$db_name$>>_app<<$app_name$>>_data_admin

SET search_path TO sch_<<$app_name$>>, comn_funs, public;
\set ECHO queries
SELECT set_config('client_min_messages', 'NOTICE', FALSE);

\i tests.functions.sql

\echo
\echo --------------------------------------------------------------
\echo NOTICE >>>>>> Testing triggers

\i tests.triggers.sql

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo
\echo --------------------------------------------------------------
\echo NOTICE >>>>>> Test data cleanup

\c <<$db_name$>> user_db<<$db_name$>>_app<<$app_name$>>_owner

SET search_path TO sch_<<$app_name$>>, comn_funs, public;
\set ECHO none
SELECT set_config('client_min_messages', 'NOTICE', FALSE);

\i tests.cleanup.sql

\echo
\echo --------------------------------------------------------------
\echo NOTICE >>>>>> Aftertest data

SELECT * FROM persons;
SELECT * FROM contacts;
SELECT * FROM contacts__emails;

\echo NOTICE >>>>>> Testing finished.
\echo --------------------------------------------------------------

\echo NOTICE >>>>>> tests.sql [END]