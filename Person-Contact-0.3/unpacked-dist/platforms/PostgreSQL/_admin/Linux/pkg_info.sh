#!/bin/sh
#
# Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
#
# All rights reserved.
#
# For information about license see COPYING file in the root directory of current nominal package
# --------------------------------------------------------------------------
# --------------------------------------------------------------------------

function echo2fds() {
        echo $1;echo $1 >&6
}
function echo2fds_n() {
        echo -n $1;echo -n $1 >&6
}

cd "`dirname $0`/../../../../_install/pkg_info" 

echo -e "\033[1;37m-------Performing DB top level metadata administration--------------------\033[0;37m"

check_db_result=`psql -f db.check.sql 2>/dev/null`

echo -e "$check_db_result"

function check_db() {
        case `echo "$check_db_result" | sed -n '/db_exists_verified_ok/ {;s/^.*db_exists_verified_ok.*$/ok/;p;q}'` in
            ok);;
            *)
            echo "Error! Database not found!"
            echo "List of available DBs:"
            psql -l
            exit 1
            ;;
        esac
}

function check_db_stdver() {
        case `echo "$check_db_result" | sed -n '/db_stdver_same_ok/ {;s/^.*db_stdver_same_ok.*$/ok/;p;q}'` in
            ok);;
            *)
            echo2fds "Warning!! DB is initialized using means other, than ones based on the STANDARD used by current package!"
            while true; do
                        echo2fds_n "Abort installation? (a[bort] | i[gnore]): "
                        read yn
                        echo $yn
                        case `echo $yn | tr 'a-z' 'A-Z' | sed 's/^ABORT$/A/;s/^IGNORE$/I/'` in
                                A)
                                echo2fds "Installation aborted by user."
                                exit 1
                                ;;
                                I)
                                echo2fds "User chose to ignore possible incompatibilities of current DBP STANDARD and one used in the base of existing DB. Continuing installation." 
                                break 
                                ;;
                                *) echo2fds 'Enter "abort" or "ignore".';;
                        esac
            done
        esac
}

function check_nodb() {
        case `echo "$check_db_result" | sed -n '/db_exists_verified_ok/ {;s/^.*db_exists_verified_ok.*$/ok/;p;q}'` in
            ok)
            echo 'Error! Can not create new database - there already is a database with such name (use "overwrite" command instead of "new")!'
            exit 1
            ;;
        esac
}

case "$1" in
	'drop')
        check_db
        check_db_stdver
        ;;
	'new')
        check_nodb
        ;;
	'overwrite')
        check_db_stdver
        ;;
	'existing')
        check_db
        check_db_stdver
        ;;
        'list')
	psql -f apps.list.sql 2>&1
        exit 2
	;;
esac;

# ------------------------------------

echo -e "\033[1;37m-------Performing application outer level metadata administration---------\033[0;37m"

check_result=`psql -f app.check.sql 2>/dev/null`
echo -e "$check_result"

function check_app() {
        case `echo "$check_result" | sed -n '/app_exists_verified_ok/ {;s/^.*app_exists_verified_ok.*$/ok/;p;q}'` in
            ok);;
            *)echo "Error! Application not found!"
            psql -f apps.list.sql
            exit 1
            ;;
        esac
}

function check_app_stdver() {
        case `echo "$check_result" | sed -n '/app_stdver_same_ok/ {;s/^.*app_stdver_same_ok.*$/ok/;p;q}'` in
            ok);;
            *)
            echo2fds "Warning!! Application in the DB is initialized using means other, than ones based on the STANDARD used by current package!"
            psql -f apps.list.sql 
            while true; do
                        echo2fds_n "Abort installation? (a[bort] | i[gnore]): "
                        read yn
                        echo $yn
                        case `echo $yn | tr 'a-z' 'A-Z' | sed 's/^ABORT$/A/;s/^IGNORE$/I/'` in
                                A)echo2fds "Installation aborted by user.";exit 1;;
                                I)echo2fds "User chose to ignore possible incompatibilities of current DBP STANDARD and one used in the base of existing application. Continuing installation." ; break ;;
                                *)echo2fds 'Enter "abort" or "ignore".';;
                        esac
            done
            ;;
        esac
}

function check_noapp() {
        case `echo "$check_result" | sed -n '/app_exists_verified_ok/ {;s/^.*app_exists_verified_ok.*$/ok/;p;q}'` in
            ok)
            echo 'Error! Can not create new application - there already is an application with such name (use "overwrite" command instead of "new")!'
            psql -f apps.list.sql 2>&1
            exit 1
            ;;
        esac
}

case "$2" in
	'drop')
        check_app
        check_app_stdver
        ;;
	'new')
        case "$1" in
                'overwrite');;
                *)check_noapp;;
        esac
        ;;
	'overwrite')
        check_app_stdver
        ;;
	'existing')
        check_app
        check_app_stdver
        ;;
        'list')
	psql -f app.pkgs.list.sql 2>&1
        exit 2
	;;
esac;

# ------------------------------------

echo -e "\033[1;37m-------Performing package level metadata administration-------------------\033[0;37m"

check_result=`psql -f app.pkg.check.sql 2>/dev/null`
echo -e "$check_result"

function check_pkg() {
        case `echo "$check_result" | sed -n '/pkg_exists_verified_ok/ {;s/^.*pkg_exists_verified_ok.*$/ok/;p;q}'` in
            ok);;
            *)echo "Error! Package in the application not found!"
            psql -f app.pkgs.list.sql 2>&1
            exit 1
            ;;
        esac
}

function check_pkgver() {
        case `echo "$check_result" | sed -n '/pkgver_same_ok/ {;s/^.*pkgver_same_ok.*$/ok/;p;q}'` in
            ok);;
            *)echo "Error! The application contains same package, but of different version!"
            psql -f app.pkgs.list.sql 2>&1
            exit 1
            ;;
        esac
}

function check_pkg_stdver() {
        case `echo "$check_result" | sed -n '/pkg_stdver_same_ok/ {;s/^.*pkg_stdver_same_ok.*$/ok/;p;q}'` in
            ok);;
            *)
            echo "Error! The application contains same package, but built based on different STANDARD version!";
            psql -f app.pkgs.list.sql 2>&1
            exit 1
            ;;
        esac
}

function check_nopkg() {
        case `echo "$check_result" | sed -n '/pkg_exists_verified_ok/ {;s/^.*pkg_exists_verified_ok.*$/ok/;p;q}'` in
            ok)
            echo "Error! Can't create a package in the application - there already is one such!"
            psql -f app.pkgs.list.sql 2>&1
            exit 1
            ;;
        esac
}

case "$3" in
	'drop')
        check_pkg
        check_pkgver
        check_pkg_stdver
        ;;
	'new')
        case "$1 $2" in
                *'overwrite'*);;
                *)check_nopkg;;
        esac
        ;;
	'overwrite')
        check_pkg
        check_pkgver
        check_pkg_stdver
        # since different template versions may require different drops
        ;;
	'existing')
        check_pkg
        check_pkgver
        check_pkg_stdver
        ;;
esac;

exit 0
