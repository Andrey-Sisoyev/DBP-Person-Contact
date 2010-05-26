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
	inst)
        echo -e "\033[1;37m-------Running schema init script schema.init.sql------------\033[0;37m"
	psql -f schema.init.sql
	;;
	*)
	echo -e "\033[1;37m-------Omitting schema init script---------------------------\033[0;37m" 
	;;
esac;

echo 

exit 0
