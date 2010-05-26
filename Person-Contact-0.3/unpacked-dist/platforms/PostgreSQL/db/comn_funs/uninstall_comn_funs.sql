-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
-- Copyright (C) 2009 Marcos Ortíz Valmaseda, Pavel Stehule
--
-- All rights reserved.
--
-- For information about license see COPYING file in the root directory of current nominal package

--------------------------------------------------------------------------
--------------------------------------------------------------------------

SET search_path = comn_funs;

-- Functions:

DROP FUNCTION IF EXISTS enter_schema_namespace(par_shema_name varchar);
DROP FUNCTION IF EXISTS leave_schema_namespace(par_prev_state t_namespace_info);
DROP FUNCTION IF EXISTS __watch(par_tag varchar, par_str anyelement);
DROP FUNCTION IF EXISTS __halt(par_tag varchar, par_str anyelement);

-- Functions written by Marcos Ortíz Valmaseda, Pavel Stehule:
-- "I wrote some perhaps useful functions for PostgreSQL. This project collect it and allows easy using of these functions."
-- (licensed under BSD License)

DROP FUNCTION IF EXISTS sprintf(fmt text, VARIADIC args "any");
DROP FUNCTION IF EXISTS sprintf(fmt text);
DROP FUNCTION IF EXISTS format(fmt text, VARIADIC args "any");
DROP FUNCTION IF EXISTS format(fmt text);
DROP FUNCTION IF EXISTS concat(VARIADIC args "any");
DROP FUNCTION IF EXISTS concat_ws(separator text, VARIADIC args "any");
DROP FUNCTION IF EXISTS concat_js(VARIADIC args "any");
DROP FUNCTION IF EXISTS concat_sql(VARIADIC args "any");
DROP FUNCTION IF EXISTS rvrs(str text);
DROP FUNCTION IF EXISTS left(str text, n int);
DROP FUNCTION IF EXISTS right(str text, n int);
DROP FUNCTION IF EXISTS chars_to_array(chars text);
DROP FUNCTION IF EXISTS next_day(d date, dow text);
DROP FUNCTION IF EXISTS last_day(d date);


-- Functions inspired by similar from Haskell:

DROP FUNCTION IF EXISTS in_list(anyelement,anyarray);
DROP FUNCTION IF EXISTS break_list(varchar, anyarray);
DROP FUNCTION IF EXISTS span_list(par_cond varchar, par_array anyarray);
DROP FUNCTION IF EXISTS split_at(par_position integer, par_array anyarray);
DROP FUNCTION IF EXISTS dropwhile_from_list_a(par_cond varchar, par_array anyarray);
DROP FUNCTION IF EXISTS dropwhile_from_list_s(par_cond varchar, par_array anyarray);
DROP FUNCTION IF EXISTS drop_from_list_a(par_count integer, par_array anyarray);
DROP FUNCTION IF EXISTS drop_from_list_s(par_count integer, par_array anyarray);
DROP FUNCTION IF EXISTS take_from_list_a(par_count int, par_array anyarray);
DROP FUNCTION IF EXISTS take_from_list_s(par_count int, par_array anyarray);
DROP FUNCTION IF EXISTS take_from_list_a(par_count int, par_array anyarray);
DROP FUNCTION IF EXISTS take_from_list_s(par_count int, par_array anyarray);
DROP FUNCTION IF EXISTS fp_replicate_a(par_count int, par_elem anyelement);
DROP FUNCTION IF EXISTS fp_replicate_s(par_count int, par_elem anyelement);
DROP FUNCTION IF EXISTS maxim(anyelement, anyelement);
DROP FUNCTION IF EXISTS minim(anyelement, anyelement);
DROP FUNCTION IF EXISTS fp_foldr(par_arr anyarray, par_fun varchar, par_accum_initfun varchar, par_stoponnull_dowe boolean);
DROP FUNCTION IF EXISTS fp_foldl(par_accum_initfun varchar, par_fun varchar, par_arr anyarray, par_stoponnull_dowe boolean);
DROP FUNCTION IF EXISTS fp_map(par_arr anyarray, par_fun varchar, par_keepnulls_dowe boolean);
DROP FUNCTION IF EXISTS fp_monoid_foldr(par_arr anyarray, par_fun varchar, par_accum anyelement, par_stoponnull_dowe boolean);
DROP FUNCTION IF EXISTS fp_monoid_foldl(par_accum anyelement, par_fun varchar, par_arr anyarray, par_stoponnull_dowe boolean);
DROP FUNCTION IF EXISTS fp_monoid_map_s(par_arr anyarray, par_fun varchar, par_keepnulls_dowe boolean);
DROP FUNCTION IF EXISTS fp_monoid_map_a(par_arr anyarray, par_fun varchar, par_keepnulls_dowe boolean);
DROP FUNCTION IF EXISTS explode_array_wi(anyarray);
DROP FUNCTION IF EXISTS first_in_list_to_satisfy(par_arr anyarray, par_crit varchar);
DROP FUNCTION IF EXISTS idx_in_list(par_arr anyarray, par_elem anyelement);

-- Taken from "PostgreSQL SQL Tricks" (http://www.postgres.cz/index.php/PostgreSQL_SQL_Tricks)

DROP FUNCTION IF EXISTS defaults(
        table_name regclass
      , OUT attname name
      , OUT type varchar
      , OUT default_val varchar
      );
DROP FUNCTION IF EXISTS sort(anyarray) ;
DROP FUNCTION IF EXISTS eval_t(varchar) ;
DROP FUNCTION IF EXISTS eval_s(varchar) ;
DROP FUNCTION IF EXISTS eval_1(varchar);

--------------------

DROP TYPE IF EXISTS t_namespace_info CASCADE;

--------------------

DROP SCHEMA IF EXISTS comn_funs CASCADE;