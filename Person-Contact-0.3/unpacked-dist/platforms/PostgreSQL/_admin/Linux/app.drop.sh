#!/bin/sh
#
# Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
#
# All rights reserved.
#
# For information about license see COPYING file in the root directory of current nominal package
# --------------------------------------------------------------------------
# --------------------------------------------------------------------------

cd "`dirname $0`/../../../../_install/app" 

case "$1" in
	drop)
	echo -e "\033[1;37m-------Running application removal script schema.drop.sql----\033[0;37m"
	psql -f schema.drop.sql
        ;;
	*)
	echo -e "\033[1;37m-------Omitting application drop script----------------------\033[0;37m" 
	;;
esac;

echo 

exit 0
