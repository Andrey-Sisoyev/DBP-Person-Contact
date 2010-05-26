#!/bin/sh
#
# Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
#
# All rights reserved.
#
# For information about license see COPYING file in the root directory of current nominal package
# --------------------------------------------------------------------------
# --------------------------------------------------------------------------

cd "`dirname $0`/../../../../_install/db" 

function echo2fds() {
        echo $1;echo $1 >&6
}

case "$1" in
	drop)
	echo -e "\033[1;37m-------Running DB removal script db.drop.sql-----------------\033[0;37m"
        contrib_path="`pg_config --sharedir`/contrib"
        contrib_path_spec="$contrib_path/$2"
	psql -f "$contrib_path_spec/uninstall_comn_funs.sql" -d "$2" "user_$2_owner"
        psql -f db.drop.sql
        rm -rf "$PGDATA""pg_tblspc/$2/default.data"
        if [ ! $? -eq 0 ]; then
                fail_notice="Deletion of DB tablespace files failed!"
                iam="$(whoami)"
                echo2fds "$fail_notice"
                if [ "$(whoami)" != 'root' ]; then
                        
                        echo2fds "Probably, superuser rights are needed!"
                        echo2fds "Retrying with sudo."
                        sudo rm -rf "$(PGDATA)pg_tblspc/$2/default.data"
                        if [ ! $? -eq 0 ]; then
                                echo2fds "$fail_notice"
                                echo2fds "MAKE SURE TO GET RID OF THIS FILE YOURSELF (if it's deletion is important to you)!"
                        fi
                fi
        fi
        ;;
	*)
	echo -e "\033[1;37m-------Omitting DB drop scripts------------------------------\033[0;37m" 
	;;
esac;

echo 

exit 0
