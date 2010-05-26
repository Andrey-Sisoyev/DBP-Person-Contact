-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
-- 
-- All rights reserved.
-- 
-- For information about license see COPYING file in the root directory of current nominal package

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\set ECHO nothing
\set ON_ERROR_STOP ON

SELECT 'db_exists_verified_ok' AS db_existance_prove
FROM pg_database WHERE datname = '<<$db_name$>>';

\c <<$db_name$>> user_<<$db_name$>>_owner

SELECT version_of_standard_based_on_which_the_db_was_created();

SELECT CASE WHEN <<$db_name$>>.public.version_of_standard_based_on_which_the_db_was_created() = '<<$pkg.std_ver$>>' THEN 'db_stdver_same_ok' ELSE '' END AS packager_same_standard_version_existance_prove;