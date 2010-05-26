-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
-- 
-- All rights reserved.
-- 
-- For information about license see COPYING file in the root directory of current nominal package

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\c <<$db_name$>> user_<<$db_name$>>_owner

-- \set ECHO nothing
\set ON_ERROR_STOP ON

-- let's make sure "dbp_applications" table exists
SELECT 'dbp_applications_table_exists_ok' AS dbp_applications_table_existance_prove FROM dbp_applications;

SELECT 'app_exists_verified_ok' AS application_existance_prove
     , CASE WHEN dbp_standard_version = '<<$pkg.std_ver$>>' THEN 'app_stdver_same_ok' ELSE '' END AS packager_same_standard_version_existance_prove
FROM dbp_applications 
WHERE application_name = '<<$app_name$>>'

