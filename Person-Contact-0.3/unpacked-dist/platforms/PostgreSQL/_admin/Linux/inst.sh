#!/bin/sh
#
# Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
#
# All rights reserved.
#
# For information about license see COPYING file in the root directory of current nominal package
# --------------------------------------------------------------------------
# --------------------------------------------------------------------------

date_time=`date +"%Y.%m.%d %H:%M:%S"`
db_inst_log="`dirname $0`/../../../../db_inst.sh.log"

# rm "$db_inst_log"
touch "$db_inst_log"

exec 6>&1 7>&2 
exec > $db_inst_log
exec 2>&1

function echo2fds() {
        echo $1;echo $1 >&6
}

db_name="$1"
db_cmd=''
app_name="$3"
app_cmd=''
pkg_cmp=''
show_log="FALSE"
goto_ln=""
shortened="FALSE"

case "$2" in
	"--drop"|"-d")     db_cmd='drop';;
	"--new"|"-n")      db_cmd='new';;
	"--overwrite"|"-w")db_cmd='overwrite';;
	"--existing"|"-e") db_cmd='existing';;
	"--list"|"-l")     db_cmd='list'
			   shortened="1";;
esac

case "$4" in
	"--drop"|"-d")     app_cmd='drop';;
	"--new"|"-n")      app_cmd='new';;
	"--overwrite"|"-w")app_cmd='overwrite';;
	"--existing"|"-e") app_cmd='existing';;
	"--list"|"-l")     app_cmd='list'
			   shortened="2";;
	*)                 app_name=''
			   shortened="1";;
esac

case "$5" in
	"--drop"|"-d")     pkg_cmd='drop';;
	"--new"|"-n")      pkg_cmd='new';;
	"--overwrite"|"-w")pkg_cmd='overwrite';;
	"--existing"|"-e") pkg_cmd='existing';;
	"")		   ;;
	*)		   shortened="2";;
esac

case "$shortened" in
	FALSE)show_log=$6;goto_ln=$7;;
	1)show_log=$3;goto_ln=$4;;
	2)show_log=$5;goto_ln=$5;;
esac

case "$show_log" in
	1) show_log="TRUE";;
	*) show_log="FALSE";;
esac

case "$goto_ln" in
	+[0-9]*g);;
	*) goto_ln="";;
esac

function finish_db_inst () {
	echo -e "\033[1;37m-----------END-OF-FILE-----------\033[0;37m" 
        exec 1>&6 2>&7 6>&- 7>&-
        echo "Log file written: $db_inst_log"
	sed -i 's/\(make sure\)/\o033[1;35m\1\o033[0m/gi;s/\(notice\)/\o033[1;35m\1\o033[0m/gi;s/\(can'"'"'t find\)/\o033[31;1m\1\o033[0m/gi;s/\(can not find\)/\o033[31;1m\1\o033[0m/gi;s/\(cannot find\)/\o033[31;1m\1\o033[0m/gi;s/\(inconsisten\)/\o033[31;1m\1\o033[0m/gi;s/\(not found\)/\o033[31;1m\1\o033[0m/gi;s/\(corrupted\)/\o033[31;1m\1\o033[0m/gi;s/\(error\)/\o033[31;1m\1\o033[0m/gi;s/\(warning\)/\o033[1;33m\1\o033[0m/gi;s/\(failed\)/\o033[31;1m\1\o033[0m/gi;s/\(failure\)/\o033[31;1m\1\o033[0m/gi;s/\(illegal\)/\o033[31;1m\1\o033[0m/gi;s/\(wrong\)/\o033[31;1m\1\o033[0m/gi;s/\(access denied\)/\o033[31;1m\1\o033[0m/gi;s/\(permission denied\)/\o033[31;1m\1\o033[0m/gi' "$db_inst_log"
	case "$show_log" in
		"TRUE")
		cat "$db_inst_log" | less -N $goto_ln
		;;
	esac
	exit $1
}	

echo -e "\033[1;37m---------START-OF-FILE-----------\033[0;37m" 
echo -e "\033[1;37mDB package install log file.\033[0;37m" 
echo -e "\033[1;37mDate, time:\033[0;37m \033[1;34m$date_time \033[0;37m" 
echo -e "\033[1;37mRun arguments ["`whoami`"]:\033[0;37m \033[1;34m$0 $1 $2 $3 $4 $5 $6\033[0;37m" 
echo 

`dirname $0`/prepare.sh "$db_name" "$db_cmd" "$app_name" "$app_cmd" "$pkg_cmd" "$show_log"

if [ ! $? -eq 0 ]; then
        echo2fds "Preparation failed!" 
	finish_db_inst 1
fi

`dirname $0`/pkg_info.sh "$db_cmd" "$app_cmd" "$pkg_cmd"

case "$?" in
        "1")
        echo2fds "Metadata administration failed!" 
	finish_db_inst 1
        ;;
        "2")
	finish_db_inst 0
        ;;
esac

case "$db_cmd $app_cmd $pkg_cmd" in
	"drop drop drop")          
		      `dirname $0`/pkg.drop.sh drop;;
	"existing existing drop")      
	              `dirname $0`/pkg.drop.sh drop;;
	*overwrite*)  `dirname $0`/pkg.drop.sh drop;;
	*)            `dirname $0`/pkg.drop.sh skip;;
esac	

if [ ! $? -eq 0 ]; then
        echo2fds "Package deinstallation failed!" 
	finish_db_inst 1
fi

case "$db_cmd $app_cmd" in
	*" drop")    `dirname $0`/app.drop.sh drop;;
	*overwrite*) `dirname $0`/app.drop.sh drop;;
	*)           `dirname $0`/app.drop.sh skip;;
esac	

if [ ! $? -eq 0 ]; then
        echo2fds "Application deinstallation failed!" 
	finish_db_inst 1
fi

case "$db_cmd" in
	drop|overwrite)     `dirname $0`/db.drop.sh drop "$db_name";;
	*)                  `dirname $0`/db.drop.sh skip;;
esac	

if [ ! $? -eq 0 ]; then
        echo2fds "Database deinstallation failed!" 
	finish_db_inst 1
fi

case "$db_cmd" in
	new|overwrite)     `dirname $0`/db.inst.sh inst "$db_name";;
	*)                 `dirname $0`/db.inst.sh skip;;
esac	

if [ ! $? -eq 0 ]; then
        echo2fds "Database installation failed!" 
	finish_db_inst 1
fi

case "$app_cmd" in
	new|overwrite)     `dirname $0`/app.inst.sh inst;;
	*)                 `dirname $0`/app.inst.sh skip;;
esac	

if [ ! $? -eq 0 ]; then
        echo2fds "Application installation failed!" 
	finish_db_inst 1
fi

case "$pkg_cmd" in
	new|overwrite)     `dirname $0`/pkg.inst.sh inst;;
	*)                 `dirname $0`/pkg.inst.sh skip;;
esac	

if [ ! $? -eq 0 ]; then
        echo2fds "Package installation failed!" 
	finish_db_inst 1
fi

case "$db_cmd $app_cmd $pkg_cmd" in *drop*)finish_db_inst 0;; esac

`dirname $0`/tests.sh 

finish_db_inst 0
