#!/bin/sh 
#
# Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
#
# All rights reserved.
#
# For information about license see COPYING file in the root directory of current nominal package
# --------------------------------------------------------------------------
# --------------------------------------------------------------------------

if [ "$1" == "--unpack" ]; then
        echo "Error! The package is already unpacked! "
        exit 1
fi

cd `dirname $0`

variant_dir='variant'
packed_dir="packed-dist"

function pack()
{
        if [ "$1" = "--clean" ]; then
                rm -rf $packed_dir
        fi        

        mkdir "$packed_dir"
        if [ ! $? -eq 0 ]; then
               echo "Can't create '$packed_dir' directory, where to make a packed version (consider using 'clean' modifier to 'rm -rf ...', if direrectory already exists)."
               echo "Aborting."
               exit 1 
        fi
        mkdir "$packed_dir/invariant"

        find . -maxdepth 1 -mindepth 1 \( ! -name "$packed_dir" \) \( ! -name "_install" \) \( ! -name "db_inst.sh.log" \) \( ! -name ".git" \) -exec cp -Rp {} "$packed_dir/invariant" \;
        
        cd "$packed_dir/invariant"
        if [ ! $? -eq 0 ]; then
               echo "Can't enter '$packed_dir/invariant' directory, where to make a packed version."
               echo "Aborting."
               exit 1 
        fi

        mv ./docs/HOWTO    ../
        mv ./docs/NEWS     ../
        mv ./docs/PKG-INFO ../
        mv ./COPYING       ../
        
        sed -i "s_ docs/licence/COPYRIGHT_ variant/docs/licence/COPYRIGHT_"  ../COPYING
        sed -i "s_\([ \t:]*\)docs/licence/COPYRIGHT_\1variant/docs/licence/COPYRIGHT_" ../PKG-INFO

        mkdir "../$variant_dir"
        mkdir "../$variant_dir/docs"

        mv ./docs/models                "../$variant_dir/docs/"
        mv ./docs/licence               "../$variant_dir/docs/"
        mv ./platforms/PostgreSQL/pkg   "../$variant_dir/"
        mv ./platforms/PostgreSQL/data  "../$variant_dir/"
        mv ./platforms/PostgreSQL/test  "../$variant_dir/"
        
        tar cjf invariant.tar.bz2 ./*
        mv invariant.tar.bz2 ../
        cd ..
	rm -rf invariant

        # --------------------------------------------------------------------
        # ------------------PACKED INSTALLER CODE SECTION START---------------
        cat > db_inst.sh <<'__EndOfFile__'
#!/bin/sh  
#
# Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
#
# All rights reserved.
#
# For information about license see COPYING file in the root directory of current nominal package
# --------------------------------------------------------------------------
# --------------------------------------------------------------------------

if [ "$1" = "--pack" ]; then
        echo "Error! The package is already packed! "
        exit 1
fi

cd `dirname $0`

unpacked_dir='unpacked-dist'
variant_dir='variant'

function unpack()
{
        if [ "$1" = "--clean" ]; then
                rm -rf $unpacked_dir
        fi

        mkdir "$unpacked_dir"
        if [ ! $? -eq 0 ]; then
               echo "Can't create '$unpacked_dir' directory, where to make a unpacked version (consider using 'clean' modifier to 'rm -rf ...', if direrectory already exists)."
               echo "Aborting."
               exit 1 
        fi

        tar xjf invariant.tar.bz2 -C "$unpacked_dir/"

        cp            "./HOWTO"    "$unpacked_dir/docs/"
        cp            "./NEWS"     "$unpacked_dir/docs/"
        cp            "./PKG-INFO" "$unpacked_dir/docs/"
        cp            "./COPYING"  "$unpacked_dir/"
        cp -Rp "$variant_dir/docs" "$unpacked_dir/"

        cp -Rp "$variant_dir/pkg"  "$unpacked_dir/platforms/PostgreSQL/"
        cp -Rp "$variant_dir/data" "$unpacked_dir/platforms/PostgreSQL/"
        cp -Rp "$variant_dir/test" "$unpacked_dir/platforms/PostgreSQL/"

        sed -i "s_variant/docs/licence/COPYRIGHT_docs/licence/COPYRIGHT_" "$unpacked_dir/COPYING"
        sed -i "s_variant/docs/licence/COPYRIGHT_docs/licence/COPYRIGHT_" "$unpacked_dir/docs/PKG-INFO"
}

if [ $# -eq 0 ] || [ "$1" = "--man" ]; then
        cat ./HOWTO | less
elif [ "$1" = "--help" ] || [ "$1" == "-?" ] || [ "$1" == "?" ]; then
        cat ./HOWTO
elif [ "$1" = "--unpack" ]; then
        unpack "$2"
else
        unpack --clean
	$unpacked_dir/db_inst.sh $1 $2 $3 $4 $5 $6 $7
fi
__EndOfFile__
        # ------------------PACKED INSTALLER CODE SECTION END-----------------
        # --------------------------------------------------------------------
	chmod u+x db_inst.sh
}

if [ $# -eq 0 ] || [ $1 == "--man" ]; then
        cat ./docs/HOWTO | less
elif [ $1 == "--help" ] || [ $1 == "-?" ] || [ $1 == "?" ]; then
        cat ./docs/HOWTO
elif [ $1 == "--pack" ]; then
        pack $2
else
        ./platforms/PostgreSQL/_admin/Linux/inst.sh $1 $2 $3 $4 $5 $6 $7
fi

