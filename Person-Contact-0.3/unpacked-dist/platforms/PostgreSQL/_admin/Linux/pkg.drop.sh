#!/bin/sh
#
# Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
#
# All rights reserved.
#
# For information about license see COPYING file in the root directory of current nominal package
# --------------------------------------------------------------------------
# --------------------------------------------------------------------------

cd "`dirname $0`/../../../../_install/pkg" 

case "$1" in
	drop)
	echo -e "\033[1;37m-------Running package removal script structure.drop.sql-----\033[0;37m"
	psql -f structure.drop.sql
        ;;	
	*)
	echo -e "\033[1;37m-------Omitting package drop script--------------------------\033[0;37m" 
	;;
esac;

echo

exit 0
