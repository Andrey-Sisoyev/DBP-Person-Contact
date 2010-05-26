#!/bin/bash
#
# Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
#
# All rights reserved.
#
# For information about license see COPYING file in the root directory of current nominal package
# --------------------------------------------------------------------------
# -------------------------------------------------------------------------

# Tasks:
# 1) Check all input parameters
# 2) Create _install directory

root_dir="`dirname $0`/../../../.."

pkg_info_file="$root_dir/docs/PKG-INFO"
standard_file="$root_dir/docs/STANDARD"
show_log=$6

function get_tpl_field() {
        sed_script_f='/^'"$1"':/I {;s/^'"$1"':[^_a-zA-Z0-9]*\([_a-zA-Z0-9][-_a-zA-Z0-9.]*\)[^_a-zA-Z0-9.-]*.*$/\1/Ig;p;}' 
        sed -n -e "$sed_script_f" "$2" | sed -n '1 p'
}

progname='db_inst.sh'

usage=$(echo "
Allowed DB commands combinations:
   ## | <DB name> | <App. name> | This package
   ---|-----------|-------------|---------------
    1 | existing  | existing    | existing
    2 | drop      | drop        | drop
    3 | drop      | drop        |
    4 | drop      |             |     
    5 | existing  | drop        |     
    6 | existing  | existing    | drop
    7 | new       | new         | new
    8 | existing  | new         | new
    9 | existing  | existing    | new
   10 | overwrite | new         | new
   11 | existing  | overwrite   | new
   12 | existing  | existing    | overwrite
   13 | list      |             |
   14 | existing  | list        |

Commands represantations as command line arguments:
    Command   | Long form   | Short form  
   -----------|-------------|---------------
    new       | --new       | -n      
    drop      | --drop      | -d      
    existing  | --existing  | -e      
    overwrite | --overwrite | -w
    list      | --list      | -l

For the combinations 3,4,5,13,14, usage: 
    $progname <db_name> [ --drop | -d ] <app_name> [ --drop | -d ] [1 [+<line_numer>g]]
    $progname <db_name> [ --drop | -d ] [1 [+<line_numer>g]]
    $progname <db_name> [ --existing | -e ] <app_name> [ --drop | -d ] [1 [+<line_numer>g]]
    $progname <db_name> [ --list | -e ] [1 [+<line_numer>g]]
    $progname <db_name> [ --existing | -e ] <app_name> [ --list | -l ] [1 [+<line_numer>g]]

Additional commands:
    $progname --pack   [--clean]
    $progname --unpack [--clean]
    $progname ( --help | -? | ? )
    $progname [ --man ]

Run program without arguments to read manual.
")

case "$1" in
        [_a-z][_a-z0-9]*);;
        *)
	echo -e "Database name must satisfy pattern '[_a-z][_a-z0-9]*' (notice: uppercase is not supported!)."
	echo -e "You provided this: '$1'" | cat -A
	exit 1
        ;;
esac

# by here the commands are already parsed (by caller script)
echo "$2 $4 $5"
case "$2 $4 $5" in
        "new new new");;
	"existing new new");;
	"existing existing new");;
	"drop drop drop");;
	"drop drop ");;
	"drop  ");;
	"existing drop ");;
	"existing existing drop");;
	"existing existing existing");;
       	"overwrite new new");;
	"existing overwrite new");;
	"existing existing overwrite");;
	"list  ");;
	"existing list ");;
	*)
	echo -e "Error! Unallowed combination of administration commands. 
        $usage"
	echo -e "You provided this: '$2 $4 $5'"
	exit 1
	;;
esac;

case "$4" in
        "");;
        *)
        case "$3" in
	        [_a-z][_a-z0-9]*);;
        	*)
		echo -e "Application name must satisfy pattern '[_a-z][_a-z0-9]*' (notice: uppercase is not supported!)."
		echo -e "You provided this: '$3'" | cat -A
		exit 1
		;;
        esac
        ;;
esac

case $PGDATA in
	'')echo "Failed! PGDATA environment variable must be set.";exit 1;;
esac;

scripts_dir="`dirname $0`/../.."
inst_dir="$root_dir/_install"

rm -rf $inst_dir
mkdir $inst_dir

cp -Rp "$scripts_dir/db"       "$inst_dir/"
cp -Rp "$scripts_dir/app"      "$inst_dir/"
cp -Rp "$scripts_dir/pkg"      "$inst_dir/"
cp -Rp "$scripts_dir/data"     "$inst_dir/"
cp -Rp "$scripts_dir/test"     "$inst_dir/"
cp -Rp "$scripts_dir/pkg_info" "$inst_dir/"

   pkg_name=`get_tpl_field "Name"     $pkg_info_file 2>&1`
    pkg_ver=`get_tpl_field "Version"  $pkg_info_file 2>&1`
pkg_std_ver=`get_tpl_field "Standard" $standard_file 2>&1`

case "$pkg_name" in
        [_a-zA-Z0-9][-_a-zA-Z0-9.]*);;
        *)
        echo -e "Package name (in file PKG-INFO) must satisfy pattern '[_a-zA-Z0-9][-_a-zA-Z0-9.]*'."
        echo -e "You provided this: '$pkg_name'" | cat -A
        exit 1
        ;;
esac

case "$pkg_ver" in
        [_a-zA-Z0-9][-_a-zA-Z0-9.]*);;
        *)
        echo -e "Package version (in file PKG-INFO) must satisfy pattern '[_a-zA-Z0-9][-_a-zA-Z0-9.]*'."
        echo -e "You provided this: '$pkg_ver'" | cat -A
        exit 1
        ;;
esac

case "$pkg_std_ver" in
        [_a-zA-Z0-9][-_a-zA-Z0-9.]*);;
        *)
        echo -e "Standard version (in file STANDARD) must satisfy pattern '[_a-zA-Z0-9][-_a-zA-Z0-9.]*'."
        echo -e "You provided this: '$pkg_std_ver'" | cat -A
        exit 1
        ;;
esac

pkg_name_p=`echo $pkg_name | tr '[A-Z]' '[a-z]' | sed 's/[^_a-z0-9]/_/g'`
 pkg_ver_p=`echo  $pkg_ver | tr '[A-Z]' '[a-z]' | sed 's/[^_a-z0-9]/_/g'`

sed_script='s/<<$db_name$>>/'"$1"'/g;s/<<$app_name$>>/'"$3"'/g;s_<<$PGDATA$>>_'"$PGDATA"'_g;s/<<$pkg\.name$>>/'"$pkg_name"'/g;s/<<$pkg\.name_p$>>/'"$pkg_name_p"'/g;s/<<$pkg\.ver$>>/'"$pkg_ver"'/g;s/<<$pkg\.ver_p$>>/'"$pkg_ver_p"'/g;s/<<$pkg\.std_ver$>>/'"$pkg_std_ver"'/g'

find "$inst_dir" -name "*.sql" -exec sed -i "$sed_script" {} \;
