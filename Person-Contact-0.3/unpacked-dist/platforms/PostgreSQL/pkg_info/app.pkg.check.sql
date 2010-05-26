-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For information about license see COPYING file in the root directory of current nominal package

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\c <<$db_name$>> user_<<$db_name$>>_owner

SET search_path TO sch_<<$app_name$>>; -- sets only for current session
\set ECHO nothing
\set ON_ERROR_STOP ON

SELECT 'dbp_packages_table_exists_ok' AS dbp_packages_table_existance_prove FROM dbp_packages LIMIT 1;

SELECT 'pkg_exists_verified_ok' AS package_existance_prove
FROM dbp_packages
WHERE package_name    = '<<$pkg.name$>>';

SELECT 'pkgver_same_ok' AS package_same_version_existance_prove
FROM dbp_packages
WHERE package_name    = '<<$pkg.name$>>'
  AND package_version = '<<$pkg.ver$>>';

SELECT CASE WHEN dbp_standard_version = '<<$pkg.std_ver$>>' THEN 'pkg_stdver_same_ok' ELSE '' END  AS packager_same_standard_version_existance_prove
FROM dbp_packages
WHERE package_name    = '<<$pkg.name$>>'
  AND package_version = '<<$pkg.ver$>>';
