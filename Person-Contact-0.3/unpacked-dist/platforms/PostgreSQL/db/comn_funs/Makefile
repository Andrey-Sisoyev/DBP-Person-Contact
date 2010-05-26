# -- Copyright (C) 2009 Marcos Ortíz Valmaseda, Pavel Stehule
# --
# -- All rights reserved.
# --
# -- Licensed using BSD License.
# -- For information about license see COPYING file in the root directory of current nominal package
# 
# --------------------------------------------------------------------------
# --------------------------------------------------------------------------

MODULES = comn_funs
DATA_built = comn_funs.sql
DATA = uninstall_comn_funs.sql
REGRESS = comn_funs

ifdef USE_PGXS
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
else
subdir = contrib/citext
top_builddir = ../..
include $(top_builddir)/src/Makefile.global
include $(top_srcdir)/contrib/contrib-global.mk
endif
