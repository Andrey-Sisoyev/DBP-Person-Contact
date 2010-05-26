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
	inst)
        echo -e "\033[1;37m-------Running DB init script db.init.sql--------------------\033[0;37m"
        psql -f db.init.sql
        
        contrib_path="`pg_config --sharedir`/contrib"
        contrib_path_spec="$contrib_path/$2"
        f1_e=0
        f2_e=0
        fail_notice="Installation of database schema containig additional functions for common use failed!"
        if [ -f "$contrib_path/comn_funs.sql" ]; then
                f1_e=1
                mv "$contrib_path/comn_funs.sql" "$contrib_path/comn_funs.sql.old" 
                if [ ! $? -eq 0 ]; then
                        iam="$(whoami)"
                        echo2fds "$fail_notice Can't guard legacy files!" 
                        echo2fds "Probably, superuser rights are needed!" 
                        echo2fds "Retrying with sudo." 
                        sudo mv "$contrib_path/comn_funs.sql" "$contrib_path/comn_funs.sql.old" 
                        sudo chown "$iam:$iam" "$contrib_path/comn_funs.sql.old"
                fi
        fi
        if [ -f "$contrib_path/comn_funs.sql" ]; then
                f2_e=1
                mv "$contrib_path/comn_funs.sql" "$contrib_path/uninstall_comn_funs.sql.old"
                if [ ! $? -eq 0 ]; then
                        iam="$(whoami)"
                        echo2fds "$fail_notice Can't guard legacy files!"
                        echo2fds "Probably, superuser rights are needed!"
                        echo2fds "Retrying with sudo."
                        sudo mv "$contrib_path/comn_funs.sql" "$contrib_path/uninstall_comn_funs.sql.old"
                        sudo chown "$iam:$iam" "$contrib_path/uninstall_comn_funs.sql.old"
                fi
        fi
        
        cd comn_funs
        
        USE_PGXS=1 make install
        if [ ! $? -eq 0 ]; then
                iam="$(whoami)"
                echo2fds "$fail_notice"
                if [ "$(whoami)" != 'root' ]; then
                        
                        echo2fds "Probably, superuser rights are needed!"
                        echo2fds "Retrying with sudo."
                        sudo USE_PGXS=1 make install
                        if [ ! $? -eq 0 ]; then
                                echo2fds "$fail_notice Compile-build-install failed for C functions!"
                                exit 1
                        fi

                        sudo mkdir "$contrib_path_spec"
                        sudo mv "$contrib_path/comn_funs.sql" "$contrib_path_spec/"
                        sudo mv "$contrib_path/uninstall_comn_funs.sql" "$contrib_path_spec/"
                        if [ $f1_e -eq 1 ]; then sudo mv "$contrib_path/comn_funs.sql.old" "$contrib_path/comn_funs.sql"; fi
                        if [ $f2_e -eq 1 ]; then sudo mv "$contrib_path/uninstall_comn_funs.sql.old" "$contrib_path/comn_funs.sql"; fi
                        sudo chown -R "$iam:$iam" "$contrib_path_spec"
                else 
                        exit 1
                fi
        else
                mkdir "$contrib_path_spec"
                mv "$contrib_path/comn_funs.sql" "$contrib_path_spec/"
                mv "$contrib_path/uninstall_comn_funs.sql" "$contrib_path_spec/"
                if [ $f1_e -eq 1 ]; then mv "$contrib_path/comn_funs.sql.old" "$contrib_path/comn_funs.sql"; fi
                if [ $f2_e -eq 1 ]; then mv "$contrib_path/uninstall_comn_funs.sql.old" "$contrib_path/comn_funs.sql" ; fi
        fi
        
        cd ..
        psql -f "$contrib_path_spec/comn_funs.sql" -d "$2" "user_$2_owner"
        ;;
	*)
	echo -e "\033[1;37m-------Omitting DB init script-------------------------------\033[0;37m" 
	;;
esac;

echo 

exit 0
