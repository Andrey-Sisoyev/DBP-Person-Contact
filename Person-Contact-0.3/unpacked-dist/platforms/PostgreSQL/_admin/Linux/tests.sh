#!/bin/sh
#
# Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
#
# All rights reserved.
#
# For information about license see COPYING file in the root directory of current nominal package
# --------------------------------------------------------------------------
# --------------------------------------------------------------------------

cd "`dirname $0`/../../../../_install/test" 

echo -e "\033[1;37m-------Performing tests:------------------------------------------------\033[0;37m" 
psql -f ./tests.sql

echo

exit 0
