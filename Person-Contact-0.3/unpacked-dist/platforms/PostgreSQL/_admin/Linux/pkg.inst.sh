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
	inst)
	echo -e "\033[1;37m-------Running package init script structure.init.sql--------\033[0;37m"
	psql -f structure.init.sql
	;;
	*)
	echo -e "\033[1;37m-------Omitting package init script-------------------------\033[0;37m" 
	;;
esac;

echo

exit 0
