-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
-- Copyright (C) 2009 Marcos Ortíz Valmaseda, Pavel Stehule
--
-- All rights reserved.
--
-- For information about license see COPYING file in the root directory of current nominal package

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- Adjust this setting to control where the objects get created.
CREATE SCHEMA comn_funs;
COMMENT ON SCHEMA comn_funs IS '
This schema is a public library for various helpers and utility functions for public common use.
It comes (is installed) with DB packages based on template "DBP-tpl" and standard "DB PACKAGING STANDARD" developed by Andrey Sisoyev for free public use (project repository: http://github.com/Andrey-Sisoyev/DBP-tpl).
If you are sure, that some functions are worth to add here, you are welcom to contribute - write me!';
GRANT USAGE ON SCHEMA comn_funs TO PUBLIC;

SET search_path = comn_funs;

----------------------------------------------------------------------------
----------------------------------------------------------------------------
----------------------------------------------------------------------------
----------------------------------------------------------------------------

-- Service functions:

CREATE TYPE t_namespace_info AS (prev_search_path varchar, sp_changed boolean);

CREATE OR REPLACE FUNCTION enter_schema_namespace(par_shema_name varchar) RETURNS t_namespace_info
STRICT LANGUAGE plpgsql
AS $$
DECLARE
        prev_search_path varchar;
        sp_changed boolean:= FALSE;
        r comn_funs.t_namespace_info;
BEGIN
        SELECT current_setting('search_path') INTO prev_search_path;
        IF prev_search_path NOT LIKE par_shema_name || '%' THEN
                PERFORM set_config('search_path', par_shema_name || ',' || prev_search_path, TRUE);
                sp_changed:= TRUE;
        END IF;
        r.prev_search_path:= prev_search_path; r.sp_changed:= sp_changed;
        RETURN r;
END;
$$;

COMMENT ON FUNCTION enter_schema_namespace(par_shema_name varchar) IS
'Usage pattern:
=====================================================
CREATE OR REPLACE FUNCTION <my_func>(<params>) RETURNS <return_type> LANGUAGE plpgsql AS $$
DECLARE
        <variables_declarations>
        namespace_info comn_funs.t_namespace_info;
BEGIN
        namespace_info := comn_funs.enter_schema_namespace(''<schema_name>'');

        <function_body>

        PERFORM leave_schema_namespace(namespace_info);
        RETURN <return_value>;
END;
$$;
=====================================================
But dont forget, that often better style would be writing like this:
        CREATE OR REPLACE FUNCTION <my_func>(<params>) RETURNS <return_type> LANGUAGE plpgsql SET search_path TO <schema_name>, comn_funs, public AS $$ ... $$;
';

-----------

CREATE OR REPLACE FUNCTION leave_schema_namespace(par_prev_state t_namespace_info) RETURNS VOID
STRICT LANGUAGE plpgsql
AS $$
BEGIN
        IF par_prev_state.sp_changed THEN
                PERFORM set_config('search_path', par_prev_state.prev_search_path, TRUE);
        END IF;
        RETURN;
END;
$$;

-----------

CREATE OR REPLACE FUNCTION __watch(par_tag varchar, par_str anyelement) RETURNS anyelement
IMMUTABLE LANGUAGE plpgsql
AS $$
BEGIN RAISE WARNING '--------------->>>>>>>>>>>> %: %', par_tag, par_str; RETURN par_str; END; $$;

-----------

CREATE OR REPLACE FUNCTION __halt(par_tag varchar, par_str anyelement) RETURNS anyelement
IMMUTABLE LANGUAGE plpgsql
AS $$
BEGIN RAISE EXCEPTION '--------------->>>>>>>>>>>> %: %', par_tag, par_str; END; $$;

----------------------------------------------------------------------------
----------------------------------------------------------------------------

-- Functions written by Marcos Ortíz Valmaseda, Pavel Stehule:
-- "I wrote some perhaps useful functions for PostgreSQL. This project collect it and allows easy using of these functions."
-- (licensed under BSD License)

CREATE OR REPLACE FUNCTION sprintf(fmt text, VARIADIC args "any") RETURNS text
IMMUTABLE LANGUAGE C
AS '$libdir/comn_funs','pst_sprintf';

COMMENT ON FUNCTION sprintf(fmt text, VARIADIC args "any") IS
'A wrapper for libc vprintf function.
Ensure PostgreSQL -> C casting.
';

--------------------

CREATE OR REPLACE FUNCTION sprintf(fmt text) RETURNS text
IMMUTABLE LANGUAGE C
AS '$libdir/comn_funs','pst_sprintf_nv';

COMMENT ON FUNCTION sprintf(fmt text) IS
'Only wrapper around sprintf(fmt text, VARIADIC args "any") function.';

--------------------

CREATE OR REPLACE FUNCTION format(fmt text, VARIADIC args "any") RETURNS text
IMMUTABLE LANGUAGE C
AS '$libdir/comn_funs','pst_format';

COMMENT ON FUNCTION format(fmt text, VARIADIC args "any") IS
'Format message - replace char % by parameter value.';

--------------------

CREATE OR REPLACE FUNCTION format(fmt text) RETURNS text
IMMUTABLE LANGUAGE C
AS '$libdir/comn_funs','pst_format_nv';

COMMENT ON FUNCTION format(fmt text) IS
'Only wrapper around format(fmt text, VARIADIC args "any") function.';

--------------------

CREATE OR REPLACE FUNCTION concat(VARIADIC args "any") RETURNS text
IMMUTABLE LANGUAGE C
AS '$libdir/comn_funs','pst_concat';

COMMENT ON FUNCTION concat(VARIADIC args "any") IS
'Concat values to comma separated list. This function is NULL safe. NULL values are skipped.';

--------------------

CREATE OR REPLACE FUNCTION concat_ws(separator text, VARIADIC args "any") RETURNS text
IMMUTABLE LANGUAGE C
AS '$libdir/comn_funs','pst_concat_ws';

COMMENT ON FUNCTION concat_ws(separator text, VARIADIC args "any") IS
'Concat values representations with custom separator. This function is NULL safe. NULL values are skipped.';

--------------------

CREATE OR REPLACE FUNCTION concat_sql(VARIADIC args "any") RETURNS text
IMMUTABLE LANGUAGE C
AS '$libdir/comn_funs','pst_concat_sql';

COMMENT ON FUNCTION concat_sql(VARIADIC args "any") IS
'Concat string with respect to SQL format.
This is NULL safe. NULLs values are transformated to "NULL" string.';

--------------------

CREATE OR REPLACE FUNCTION concat_js(VARIADIC args "any") RETURNS text
IMMUTABLE LANGUAGE C
AS '$libdir/comn_funs','pst_concat_js';

COMMENT ON FUNCTION concat_js(VARIADIC args "any") IS
'Concat string with respect to JSON format.
This is NULL safe. NULLs values are transformated to "null" string.
JSON uses lowercase characters for constants - see www.json.org
';

--------------------

CREATE OR REPLACE FUNCTION left(str text, n int) RETURNS text
IMMUTABLE STRICT LANGUAGE C
AS '$libdir/comn_funs','pst_left';

COMMENT ON FUNCTION left(str text, n int) IS
'Returns first n chars. When n is negative, then it returns chars from n+1 position.';

--------------------

CREATE OR REPLACE FUNCTION right(str text, n int) RETURNS text
IMMUTABLE STRICT LANGUAGE C
AS '$libdir/comn_funs','pst_right';

COMMENT ON FUNCTION right(str text, n int) IS
'Returns last n chars from string. When n is negative, then returns string without last n chars.';

--------------------

CREATE OR REPLACE FUNCTION rvrs(str text) RETURNS text
IMMUTABLE STRICT LANGUAGE C
AS '$libdir/comn_funs','pst_rvrs';

COMMENT ON FUNCTION rvrs(str text) IS
'Returns reversed string.';

--------------------

CREATE OR REPLACE FUNCTION chars_to_array(str text) RETURNS text[]
IMMUTABLE STRICT LANGUAGE C
AS '$libdir/comn_funs','pst_chars_to_array';

--------------------

CREATE OR REPLACE FUNCTION next_day(day date, dow text) RETURNS date
IMMUTABLE STRICT LANGUAGE C
AS '$libdir/comn_funs','pst_next_day';

COMMENT ON FUNCTION next_day(day date, dow text) IS
'Returns the first weekday that is greater than a date value.';

--------------------

CREATE OR REPLACE FUNCTION last_day(day date) RETURNS date
IMMUTABLE STRICT LANGUAGE C
AS '$libdir/comn_funs','pst_last_day';

COMMENT ON FUNCTION last_day(day date) IS
'Returns last day of the month.';

----------------------------------------------------------------------------
----------------------------------------------------------------------------
----------------------------------------------------------------------------
----------------------------------------------------------------------------
-- Functions inspired by similar from Haskell:

CREATE OR REPLACE FUNCTION idx_in_list(par_arr anyarray, par_elem anyelement) RETURNS integer
IMMUTABLE STRICT LANGUAGE plpgsql
AS $$
DECLARE i integer; l integer; r_found boolean;
BEGIN
        l:= array_upper(par_arr, 1);
        i:= array_lower(par_arr, 1);
        r_found:= FALSE;
        WHILE i <= l AND NOT r_found LOOP
            r_found:= coalesce(par_arr[i] = par_elem, FALSE);
            i:= i + 1;
        END LOOP;
        IF r_found THEN i:= i - 1; ELSE i:= NULL :: integer; END IF;
        RETURN i;
END;
$$;

COMMENT ON FUNCTION idx_in_list(par_arr anyarray, par_elem anyelement) IS
'Returns NULL if any of the parameters is NULL.
Returns NULL if not found.
Returns element index, if element is found (first element of the array has index = 1).

DROP TYPE IF EXISTS lll;
CREATE TYPE lll AS (a int, b int, c int);

postgres=# select idx_in_list(array[row(1,2,3),row(3,4,5),row(8,9,10)] :: lll[], row(3,4,5) :: lll);
 idx_in_list
-------------
           2
(1 row)


postgres=# select idx_in_list(array[row(1,2,3),row(3,4,5),row(8,9,10)] :: lll[], row(3,4,8) :: lll);
 idx_in_list
-------------

(1 row)
DROP TYPE IF EXISTS lll;
';

----------------------------------------------------------------------------
----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION first_in_list_to_satisfy(par_arr anyarray, par_crit varchar) RETURNS integer
IMMUTABLE STRICT LANGUAGE plpgsql
AS $$
DECLARE i integer; l integer; r_found boolean;
BEGIN
        l:= array_upper(par_arr, 1);
        i:= array_lower(par_arr, 1);
        r_found:= FALSE;
        WHILE i <= l AND NOT r_found LOOP
            EXECUTE par_crit INTO r_found USING i, par_arr[i];
            r_found:= coalesce(r_found, FALSE);
            i:= i + 1;
        END LOOP;
        IF r_found THEN i:= i - 1; ELSE i:= -1; END IF;
        RETURN i;
END;
$$;

COMMENT ON FUNCTION first_in_list_to_satisfy(par_arr anyarray, par_crit varchar) IS
'Search for the first element that would satisfy criterion given in "par_crit".
The "par_crit" must contain SELECT query, that returns boolean (NULL considered to be FALSE), and takes 2 parameters: $1 is index in array, $2 is array element.
Returns NULL if any of the parameters is NULL.
Returns -1 if not found.
Returns element index, if element is found (first element of the array has index = 1).

DROP TYPE IF EXISTS lll;
CREATE TYPE lll AS (a int, b int, c int);
postgres=# select first_in_list_to_satisfy(array[row(1,2,10),row(3,4,5),row(8,9,10),row(8,9,10)] :: lll[], ''SELECT $1 > 2 AND ($2).c = 10'');
 first_in_list_to_satisfy
--------------------------
                        3
(1 row)
DROP TYPE IF EXISTS lll;

Notice: Function uses EXECUTE. The important difference is that EXECUTE will re-plan the command on each execution, generating a plan that is specific to the current parameter values; whereas PL/pgSQL normally creates a generic plan and caches it for re-use. In situations where the best plan depends strongly on the parameter values, EXECUTE can be significantly faster; while when the plan is not sensitive to parameter values, re-planning will be a waste.
';

----------------------------------------------------------------------------
----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION explode_array_wi(anyarray) RETURNS SETOF RECORD
IMMUTABLE LANGUAGE SQL
AS $$
SELECT ($1)[s] AS elem, s AS idx FROM generate_series(array_lower($1, 1),array_upper($1, 1)) as s;
$$;

COMMENT ON FUNCTION explode_array_wi(anyarray) IS
'Doesn''t work with multidimensional arrays.
Use case:
postgres=# select a, b from explode_array_wi(array[21,32,43] :: integer[]) x(a integer, b integer);
 a  | b
----+---
 21 | 1
 32 | 2
 43 | 3
(3 rows)

DROP TYPE IF EXISTS lll;
CREATE TYPE lll AS (a int, b int, c int);
postgres=# select aa,bb from explode_array_wi(array[row(1,2,3),row(3,4,5),row(8,9,10)] :: lll[]) x(aa lll, bb int);
    aa    | bb
----------+----
 (1,2,3)  |  1
 (3,4,5)  |  2
 (8,9,10) |  3
(3 rows)
DROP TYPE IF EXISTS lll;
';

----------------------------------------------------------------------------
----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fp_monoid_map_s(par_arr anyarray, par_fun varchar, par_keepnulls_dowe boolean) RETURNS SETOF anyelement
STRICT LANGUAGE plpgsql
AS $$
DECLARE i integer; l integer; r_found boolean; j integer;
        r par_arr%TYPE; e record;
BEGIN
        l:= array_upper(par_arr, 1);
        i:= array_lower(par_arr, 1); j:= 1;
        WHILE i <= l LOOP
            EXECUTE par_fun INTO e USING i, par_arr[i];
            IF NOT par_keepnulls_dowe THEN
                IF e.elem IS NOT NULL THEN r[j]:= e.elem; j:= j + 1; END IF;
            ELSE r[j]:= e.elem; j:= j + 1; END IF;
            i:= i + 1;
        END LOOP;
        RETURN QUERY SELECT * FROM unnest(r);
END;
$$;

COMMENT ON FUNCTION fp_monoid_map_s(par_arr anyarray, par_fun varchar, par_keepnulls_dowe boolean) IS
'Analogue to "map" function from functional programming.
The "par_fun" must contain SELECT query, that returns a row with field "elem" of the same type, as is type of element of "par_arr" array, and takes 2 parameters: $1 is index in array, $2 is array element.
If "par_keepnulls_dowe" is FALSE, then resulting array won''t accumulate resulting NULL elements.
Returns NULL if any of the parameters is NULL.

DROP TYPE IF EXISTS lll;
CREATE TYPE lll AS (a int, b int, c int);
postgres=# select fp_monoid_map_s(array[row(1,2,10),row(3,4,5),row(8,9,10),row(8,9,10)] :: lll[], ''SELECT ROW(($2).a, ($2).b, $1) :: lll AS elem'', TRUE);
 fp_monoid_map_s
-----------------
 (1,2,1)
 (3,4,2)
 (8,9,3)
 (8,9,4)
(4 rows)

postgres=# select fp_monoid_map_s(
postgres(#                  array[row(1,2,10),row(3,4,5),row(8,9,10),row(8,9,10)] :: lll[]
postgres(#                , ''SELECT case $1 when 2 then NULL :: lll when 3 then NULL :: lll else ROW(($2).a, ($2).b, $1) :: lll end AS elem''
postgres(#                , FALSE
postgres(#                );
 fp_monoid_map_s
-----------------
 (1,2,1)
 (8,9,4)
(2 rows)
DROP TYPE IF EXISTS lll;

Notice: Function uses EXECUTE. The important difference is that EXECUTE will re-plan the command on each execution, generating a plan that is specific to the current parameter values; whereas PL/pgSQL normally creates a generic plan and caches it for re-use. In situations where the best plan depends strongly on the parameter values, EXECUTE can be significantly faster; while when the plan is not sensitive to parameter values, re-planning will be a waste.
';

----------------------------------------------------------------------------
----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fp_monoid_map_a(par_arr anyarray, par_fun varchar, par_keepnulls_dowe boolean) RETURNS anyarray
STRICT LANGUAGE plpgsql
AS $$
DECLARE i integer; l integer; r_found boolean; j integer;
        r par_arr%TYPE; e record;
BEGIN
        l:= array_upper(par_arr, 1);
        i:= array_lower(par_arr, 1); j:= 1;
        WHILE i <= l LOOP
            EXECUTE par_fun INTO e USING i, par_arr[i];
            IF NOT par_keepnulls_dowe THEN
                IF e.elem IS NOT NULL THEN r[j]:= e.elem; j:= j + 1; END IF;
            ELSE r[j]:= e.elem; j:= j + 1; END IF;
            i:= i + 1;
        END LOOP;
        RETURN r;
END;
$$;

COMMENT ON FUNCTION fp_monoid_map_a(par_arr anyarray, par_fun varchar, par_keepnulls_dowe boolean) IS
'Analogue to "map" function from functional programming.
The "par_fun" must contain SELECT query, that returns a row with field "elem" of the same type, as is type of element of "par_arr" array, and takes 2 parameters: $1 is index in array, $2 is array element.
If "par_keepnulls_dowe" is FALSE, then resulting array won''t accumulate resulting NULL elements.
Returns NULL if any of the parameters is NULL.

DROP TYPE IF EXISTS lll;
CREATE TYPE lll AS (a int, b int, c int);
postgres=# select fp_monoid_map_a(array[row(1,2,10),row(3,4,5),row(8,9,10),row(8,9,10)] :: lll[], ''SELECT ROW(($2).a, ($2).b, $1) :: lll AS elem'', TRUE);
               fp_monoid_map_a
-------------------------------------------
 {"(1,2,1)","(3,4,2)","(8,9,3)","(8,9,4)"}
(1 row)

postgres=# select fp_monoid_map_a(
postgres(#                 array[row(1,2,10),row(3,4,5),row(8,9,10),row(8,9,10)] :: lll[]
postgres(#               , ''SELECT case $1 when 2 then NULL :: lll when 3 then NULL :: lll else ROW(($2).a, ($2).b, $1) :: lll end AS elem''
postgres(#               , FALSE
postgres(#               );
     fp_monoid_map_a
-----------------------
 {"(1,2,1)","(8,9,4)"}
(1 row)
DROP TYPE IF EXISTS lll;

Notice: Function uses EXECUTE. The important difference is that EXECUTE will re-plan the command on each execution, generating a plan that is specific to the current parameter values; whereas PL/pgSQL normally creates a generic plan and caches it for re-use. In situations where the best plan depends strongly on the parameter values, EXECUTE can be significantly faster; while when the plan is not sensitive to parameter values, re-planning will be a waste.
';

----------------------------------------------------------------------------
----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fp_monoid_foldl(par_accum anyelement, par_fun varchar, par_arr anyarray, par_stoponnull_dowe boolean) RETURNS record
LANGUAGE plpgsql
AS $$
DECLARE i integer; l integer; j integer;
        e record;
BEGIN   IF par_fun IS NULL THEN RETURN NULL; END IF;
        IF par_stoponnull_dowe IS NULL THEN RETURN NULL; END IF;
        l:= COALESCE(array_upper(par_arr, 1), 0);
        i:= array_lower(par_arr, 1);
        SELECT par_accum AS elem, FALSE AS stop_shouldwe INTO e;
        WHILE i <= l LOOP
            EXECUTE par_fun INTO e USING i, par_arr[i], e.elem;
            IF par_stoponnull_dowe THEN
                IF e.elem IS NULL THEN RETURN e; END IF;
            END IF;
            IF e.stop_shouldwe THEN RETURN e; END IF;
            i:= i + 1;
        END LOOP;
        RETURN e;
END;
$$;

COMMENT ON FUNCTION fp_monoid_foldl(par_accum anyelement, par_fun varchar, par_arr anyarray, par_stoponnull_dowe boolean) IS
'Analogue to "foldl" function from functional programming.
The "par_fun" must contain SELECT query, that takes 3 parameters:
** $1 is an index in array
** $2 is an array element
** $3 is current accumulator
; and returns a row with 2 fields:
** "elem" new accumulator state
** "stop_shouldwe" :: boolean signalizing fold to stop and return current accumulator.
If "par_stoponnull_dowe" is TRUE, then whenever accumulator becomes NULL fold stops and NULL is returned (but N/A to initial "par_accum").


DROP TYPE IF EXISTS lll;
CREATE TYPE lll AS (a int, b int, c int);
postgres=# select fp_monoid_foldl(
postgres(#           row(1000,1000,1000) :: lll
postgres(#         , ''SELECT ROW(($2).a + ($3).a, ($2).b + ($3).b, ($2).c + ($3).c) :: lll AS elem
postgres''#                 , $1 = 3 AS stop_shouldwe''
postgres(#         , array[row(1,2,10),row(3,4,5),row(8,9,10),row(8,9,10)] :: lll[]
postgres(#         , TRUE
postgres(#         );
    fp_monoid_foldl
------------------------
 ("(1012,1015,1025)",t)
(1 row)
DROP TYPE IF EXISTS lll;

Notice: Function uses EXECUTE. The important difference is that EXECUTE will re-plan the command on each execution, generating a plan that is specific to the current parameter values; whereas PL/pgSQL normally creates a generic plan and caches it for re-use. In situations where the best plan depends strongly on the parameter values, EXECUTE can be significantly faster; while when the plan is not sensitive to parameter values, re-planning will be a waste.
';

----------------------------------------------------------------------------
----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fp_monoid_foldr(par_arr anyarray, par_fun varchar, par_accum anyelement, par_stoponnull_dowe boolean) RETURNS record
LANGUAGE plpgsql
AS $$
DECLARE i integer; l integer; j integer; lo_b integer;
        e record;
BEGIN   IF par_fun IS NULL THEN RETURN NULL; END IF;
        IF par_stoponnull_dowe IS NULL THEN RETURN NULL; END IF;
        l:= COALESCE(array_upper(par_arr, 1), 0);
        i:= l; lo_b:= array_lower(par_arr, 1);
        SELECT par_accum AS elem, FALSE AS stop_shouldwe INTO e;
        WHILE i >= lo_b LOOP
            EXECUTE par_fun INTO e USING i, par_arr[i], e.elem;
            IF par_stoponnull_dowe THEN
                IF e.elem IS NULL THEN RETURN e; END IF;
            END IF;
            IF e.stop_shouldwe THEN RETURN e; END IF;
            i:= i - 1;
        END LOOP;
        RETURN e;
END;
$$;

COMMENT ON FUNCTION fp_monoid_foldr(par_arr anyarray, par_fun varchar, par_accum anyelement, par_stoponnull_dowe boolean) IS
'Analogue to "foldr" function from functional programming.
The "par_fun" must contain SELECT query, that takes 3 parameters:
** $1 is an index in array
** $2 is an array element
** $3 is current accumulator
; and returns a row with 2 fields:
** "elem" new accumulator state
** "stop_shouldwe" :: boolean signalizing fold to stop and return current accumulator.
If "par_stoponnull_dowe" is TRUE, then whenever accumulator becomes NULL fold stops and NULL is returned (but N/A to initial "par_accum").

DROP TYPE IF EXISTS lll;
CREATE TYPE lll AS (a int, b int, c int);
postgres=# select fp_monoid_foldr(
postgres(#           array[row(1,2,10),row(3,4,5),row(8,9,10),row(8,9,10)] :: lll[]
postgres(#         , ''SELECT ROW(($2).a + ($3).a, ($2).b + ($3).b, ($2).c + ($3).c) :: lll AS elem
postgres''#                 , $1 = 3 AS stop_shouldwe''
postgres(#         , row(1000,1000,1000) :: lll
postgres(#         , TRUE
postgres(#         );
    fp_monoid_foldr
------------------------
 ("(1016,1018,1020)",t)
(1 row)
DROP TYPE IF EXISTS lll;

Notice: Function uses EXECUTE. The important difference is that EXECUTE will re-plan the command on each execution, generating a plan that is specific to the current parameter values; whereas PL/pgSQL normally creates a generic plan and caches it for re-use. In situations where the best plan depends strongly on the parameter values, EXECUTE can be significantly faster; while when the plan is not sensitive to parameter values, re-planning will be a waste.
';

----------------------------------------------------------------------------
----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fp_map(par_arr anyarray, par_fun varchar, par_keepnulls_dowe boolean) RETURNS SETOF RECORD
STRICT LANGUAGE plpgsql
AS $$
DECLARE i integer; l integer;
        e record;
BEGIN
        l:= array_upper(par_arr, 1);
        i:= array_lower(par_arr, 1);
        WHILE i <= l LOOP
            EXECUTE par_fun INTO e USING i, par_arr[i];
            IF NOT par_keepnulls_dowe THEN
                IF e IS NOT NULL THEN RETURN NEXT e; END IF;
            ELSE RETURN NEXT e; END IF;
            i:= i + 1;
        END LOOP;
        RETURN;
END;
$$;

COMMENT ON FUNCTION fp_map(par_arr anyarray, par_fun varchar, par_keepnulls_dowe boolean) IS
'Analogue to "map" function from functional programming.
The "par_fun" must contain SELECT query, that takes 2 parameters: $1 is index in array, $2 is array element.
If "par_keepnulls_dowe" is FALSE, then resulting array won''t accumulate resulting NULL elements.
Returns NULL if any of the parameters is NULL.

DROP TYPE IF EXISTS lll;
CREATE TYPE lll AS (a int, b int, c int);
DROP TYPE IF EXISTS lll2;
CREATE TYPE lll2 AS (a int, b int, c int, d int);
postgres=# select * FROM fp_map(
postgres(#                  array[row(1,2,10),row(3,4,5),row(8,9,10),row(8,9,10)] :: lll[]
postgres(#                , ''SELECT case $1 when 2 then NULL :: lll2 when 3 then NULL :: lll2 else ROW(($2).a, ($2).b, $1, ($2).a + ($2).b + ($2).c)  :: lll2 end as sfsdfsf''
postgres(#                , FALSE
postgres(#                ) AS (sfsdfsf lll2);
  sfsdfsf
------------
 (1,2,1,13)
 (8,9,4,27)
(2 rows)
DROP TYPE IF EXISTS lll;
DROP TYPE IF EXISTS lll2;

Notice: Function uses EXECUTE. The important difference is that EXECUTE will re-plan the command on each execution, generating a plan that is specific to the current parameter values; whereas PL/pgSQL normally creates a generic plan and caches it for re-use. In situations where the best plan depends strongly on the parameter values, EXECUTE can be significantly faster; while when the plan is not sensitive to parameter values, re-planning will be a waste.
';

----------------------------------------------------------------------------
----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fp_foldl(par_accum_initfun varchar, par_fun varchar, par_arr anyarray, par_stoponnull_dowe boolean) RETURNS record
LANGUAGE plpgsql
AS $$
DECLARE i integer; l integer; j integer;
        e record;
BEGIN   IF par_fun IS NULL THEN RETURN NULL; END IF;
        IF par_stoponnull_dowe IS NULL THEN RETURN NULL; END IF;
        l:= COALESCE(array_upper(par_arr, 1), 0);
        i:= array_lower(par_arr, 1);
        EXECUTE 'SELECT FALSE AS stop_shouldwe, * FROM (' || par_accum_initfun || ') AS xxx___' INTO e;
        WHILE i <= l LOOP
            EXECUTE par_fun INTO e USING i, par_arr[i], e.elem;
            IF par_stoponnull_dowe THEN
                IF e.elem IS NULL THEN RETURN e; END IF;
            END IF;
            IF e.stop_shouldwe THEN RETURN e; END IF;
            i:= i + 1;
        END LOOP;
        RETURN e;
END;
$$;

COMMENT ON FUNCTION fp_foldl(par_accum_initfun varchar, par_fun varchar, par_arr anyarray, par_stoponnull_dowe boolean) IS
'Analogue to "foldl" function from functional programming.
The "par_accum_initfun" must cotain SELECT query, that in "elem" field returns accumulator initial state. Such initialization way (using dynamic query) is chosen due to constraints of type polimorphism in PostgreSQL.
The "par_fun" must contain SELECT query, that takes 3 parameters:
** $1 is an index in array
** $2 is an array element
** $3 is current accumulator
; and returns a row with 2 fields:
** "elem" new accumulator state.
** "stop_shouldwe" :: boolean signalizing fold to stop and return current accumulator.
If "par_stoponnull_dowe" is TRUE, then whenever accumulator becomes NULL fold stops and NULL is returned (but N/A to initial "par_accum").


DROP TYPE IF EXISTS lll;
CREATE TYPE lll AS (a int, b int, c int);
DROP TYPE IF EXISTS lll2;
CREATE TYPE lll2 AS (a int, b int, c int, d int);

postgres=# select fp_foldl(
postgres(#            ''SELECT row(1000,1000,1000,1000) :: lll2 AS elem''
postgres(#          , ''SELECT ROW(($2).a + ($3).a, ($2).b + ($3).b, ($2).c + ($3).c, $1 + ($3).d) :: lll2 AS elem
postgres''#                  , $1 = 3 AS stop_shouldwe''
postgres(#          , array[row(1,2,10),row(3,4,5),row(8,9,10),row(18,19,20)] :: lll[]
postgres(#          , TRUE
postgres(#          );
          fp_foldl
-----------------------------
 ("(1012,1015,1025,1006)",t)
(1 row)

DROP TYPE IF EXISTS lll;
DROP TYPE IF EXISTS lll2;

Notice: Function uses EXECUTE. The important difference is that EXECUTE will re-plan the command on each execution, generating a plan that is specific to the current parameter values; whereas PL/pgSQL normally creates a generic plan and caches it for re-use. In situations where the best plan depends strongly on the parameter values, EXECUTE can be significantly faster; while when the plan is not sensitive to parameter values, re-planning will be a waste.
';

----------------------------------------------------------------------------
----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fp_foldr(par_arr anyarray, par_fun varchar, par_accum_initfun varchar, par_stoponnull_dowe boolean) RETURNS record
LANGUAGE plpgsql
AS $$
DECLARE i integer; l integer; j integer; lo_b integer;
        e record;
BEGIN   IF par_fun IS NULL THEN RETURN NULL; END IF;
        IF par_stoponnull_dowe IS NULL THEN RETURN NULL; END IF;
        l:= COALESCE(array_upper(par_arr, 1), 0);
        i:= l; lo_b:= array_lower(par_arr, 1);
        EXECUTE 'SELECT FALSE AS stop_shouldwe, * FROM (' || par_accum_initfun || ') AS xxx___' INTO e;
        WHILE i >= lo_b LOOP
            EXECUTE par_fun INTO e USING i, par_arr[i], e.elem;
            IF par_stoponnull_dowe THEN
                IF e.elem IS NULL THEN RETURN e; END IF;
            END IF;
            IF e.stop_shouldwe THEN RETURN e; END IF;
            i:= i - 1;
        END LOOP;
        RETURN e;
END;
$$;

COMMENT ON FUNCTION fp_foldr(par_arr anyarray, par_fun varchar, par_accum_initfun varchar, par_stoponnull_dowe boolean) IS
'Analogue to "foldr" function from functional programming.
The "par_accum_initfun" must cotain SELECT query, that in "elem" field returns accumulator initial state. Such initialization way (using dynamic query) is chosen due to constraints of type polimorphism in PostgreSQL.
The "par_fun" must contain SELECT query, that takes 3 parameters:
** $1 is an index in array
** $2 is an array element
** $3 is current accumulator
; and returns a row with 2 fields:
** "elem" of the same type, as is type of "par_accum"
** "stop_shouldwe" :: boolean signalizing fold to stop and return current accumulator.
If "par_stoponnull_dowe" is TRUE, then whenever accumulator becomes NULL fold stops and NULL is returned (but N/A to initial "par_accum").

DROP TYPE IF EXISTS lll;
CREATE TYPE lll AS (a int, b int, c int);

postgres=# select fp_foldr(
postgres(#            array[row(1,2,10),row(3,4,5),row(8,9,10),row(18,19,20)] :: lll[]
postgres(#          , ''SELECT ROW(($2).a + ($3).a, ($2).b + ($3).b, ($2).c + ($3).c, $1 + ($3).d) :: lll2 AS elem
postgres''#                  , $1 = 3 AS stop_shouldwe''
postgres(#          , ''SELECT row(1000,1000,1000,1000) :: lll2 AS elem''
postgres(#          , TRUE
postgres(#          );
          fp_foldr
-----------------------------
 ("(1026,1028,1030,1007)",t)
(1 row)

DROP TYPE IF EXISTS lll;

Notice: Function uses EXECUTE. The important difference is that EXECUTE will re-plan the command on each execution, generating a plan that is specific to the current parameter values; whereas PL/pgSQL normally creates a generic plan and caches it for re-use. In situations where the best plan depends strongly on the parameter values, EXECUTE can be significantly faster; while when the plan is not sensitive to parameter values, re-planning will be a waste.
';

----------------------------------------------------------------------------
----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION minim(anyelement, anyelement) RETURNS anyelement
STRICT IMMUTABLE LANGUAGE SQL
AS $$
        SELECT CASE $1 > $2 WHEN TRUE THEN $2 ELSE $1 END;
$$;

CREATE OR REPLACE FUNCTION maxim(anyelement, anyelement) RETURNS anyelement
STRICT IMMUTABLE LANGUAGE SQL
AS $$
        SELECT CASE $1 > $2 WHEN TRUE THEN $1 ELSE $2 END;
$$;

----------------------------------------------------------------------------
----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fp_replicate_s(par_count int, par_elem anyelement) RETURNS SETOF anyelement
STRICT IMMUTABLE LANGUAGE plpgsql
AS $$
DECLARE i integer;
BEGIN   i:= 1;
        WHILE i <= par_count LOOP
            RETURN NEXT par_elem;
            i:= i + 1;
        END LOOP;
        RETURN;
END;
$$;

COMMENT ON FUNCTION fp_replicate_s(par_count int, par_elem anyelement) IS
'Returns set of size "par_count" all filled with "par_elem" elements.
postgres=# SELECT * FROM fp_replicate_s(4, row(1,2,3) :: lll);
 a | b | c
---+---+---
 1 | 2 | 3
 1 | 2 | 3
 1 | 2 | 3
 1 | 2 | 3
(4 rows)
';

----------------------------------------------------------------------------
----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fp_replicate_a(par_count int, par_elem anyelement) RETURNS anyarray
STRICT IMMUTABLE LANGUAGE plpgsql
AS $$
DECLARE i integer;
        r ALIAS FOR $0;
BEGIN   r:= ARRAY(SELECT ROW(a.*) AS elem FROM fp_replicate_s(par_count, par_elem) AS a);
        RETURN r;
END;
$$;

COMMENT ON FUNCTION fp_replicate_a(par_count int, par_elem anyelement) IS
'Returns array of size "par_count" all filled with "par_elem" elements.
postgres=# SELECT * FROM fp_replicate_a(4, row(1,2,3) :: lll);
              fp_replicate_a
-------------------------------------------
 {"(1,2,3)","(1,2,3)","(1,2,3)","(1,2,3)"}
(1 row)
';

----------------------------------------------------------------------------
----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION take_from_list_s(par_count int, par_array anyarray) RETURNS SETOF anyelement
STRICT IMMUTABLE LANGUAGE plpgsql
AS $$
DECLARE i integer; c integer; l integer; r par_array%TYPE;
BEGIN   i:= array_lower(par_array, 1); l:= array_upper(par_array, 1); c:= minim(i + par_count - 1, l);
        WHILE i <= c LOOP
            r[i]:= par_array[i];
            i:= i + 1;
        END LOOP;
        RETURN QUERY SELECT * FROM unnest(r);
END;
$$;

COMMENT ON FUNCTION take_from_list_s(par_count int, par_array anyarray) IS
'Takes first min("par_count", array_length("par_array")) of "par_array" array, returns set.
postgres=# SELECT * FROM take_from_list_s(2, array[row(1,2,10),row(3,4,5),row(8,9,10),row(18,19,20)] :: lll[]);
 a | b | c
---+---+----
 1 | 2 | 10
 3 | 4 |  5
(2 rows)
';

----------------------------------------------------------------------------
----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION take_from_list_a(par_count int, par_array anyarray) RETURNS anyarray
STRICT IMMUTABLE LANGUAGE plpgsql
AS $$
DECLARE i integer; c integer; l integer; r par_array%TYPE;
BEGIN   i:= array_lower(par_array, 1); l:= array_upper(par_array, 1); c:= minim(i + par_count - 1, l);
        WHILE i <= c LOOP
            r[i]:= par_array[i];
            i:= i + 1;
        END LOOP;
        RETURN r;
END;
$$;

COMMENT ON FUNCTION take_from_list_a(par_count int, par_array anyarray) IS
'Takes first min("par_count", array_length("par_array")) of "par_array" array, returns array.
postgres=# SELECT * FROM take_from_list_a(2, array[row(1,2,10),row(3,4,5),row(8,9,10),row(18,19,20)] :: lll[]);
    take_from_list_a
------------------------
 {"(1,2,10)","(3,4,5)"}
(1 row)
';

----------------------------------------------------------------------------
----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION takewhile_from_list_s(par_cond varchar, par_array anyarray) RETURNS SETOF anyelement
STRICT LANGUAGE plpgsql
AS $$
DECLARE i integer; l integer; r par_array%TYPE; b boolean;
BEGIN   i:= array_lower(par_array, 1); l:= array_upper(par_array, 1);
        b:= TRUE;
        WHILE i <= l AND b LOOP
            EXECUTE par_cond INTO b USING i, par_array[i];
            IF b IS NULL THEN RAISE EXCEPTION 'An error in "takewhile_from_list_s"! Condition check returned NULL (at index %), which is not allowed!', i; END IF;
            IF b THEN
                r[i]:= par_array[i];
            END IF;
            i:= i + 1;
        END LOOP;
        RETURN QUERY SELECT * FROM unnest(r);
END;
$$;

COMMENT ON FUNCTION take_from_list_s(par_count int, par_array anyarray) IS
'Takes elements from "par_array" array while they satisfy condition calculated by "par_cond", returns set.
Parameter "par_cond" must contain SELECT query taking 2 parameters: $1 - index in array, $2 - array element; and returning boolean: TRUE - take element and continue, FALSE don''t take element and return current result.
If execution of "par_cond" returns NULL, an exception is rised.
postgres=# SELECT * FROM takewhile_from_list_s(''SELECT $1 >= ($2).a'', array[row(1,2,10),row(2,4,5),row(8,9,10),row(18,19,20)] :: lll[]);
 a | b | c
---+---+----
 1 | 2 | 10
 2 | 4 |  5
(2 rows)

Notice: Function uses EXECUTE. The important difference is that EXECUTE will re-plan the command on each execution, generating a plan that is specific to the current parameter values; whereas PL/pgSQL normally creates a generic plan and caches it for re-use. In situations where the best plan depends strongly on the parameter values, EXECUTE can be significantly faster; while when the plan is not sensitive to parameter values, re-planning will be a waste.
';

----------------------------------------------------------------------------
----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION takewhile_from_list_a(par_cond varchar, par_array anyarray) RETURNS anyarray
STRICT LANGUAGE plpgsql
AS $$
DECLARE i integer; l integer; r par_array%TYPE; b boolean;
BEGIN   i:= array_lower(par_array, 1); l:= array_upper(par_array, 1);
        b:= TRUE;
        WHILE i <= l AND b LOOP
            EXECUTE par_cond INTO b USING i, par_array[i];
            IF b IS NULL THEN RAISE EXCEPTION 'An error in "takewhile_from_list_a"! Condition check returned NULL (at index %), which is not allowed!', i; END IF;
            IF b THEN
                r[i]:= par_array[i];
            END IF;
            i:= i + 1;
        END LOOP;
        RETURN r;
END;
$$;

COMMENT ON FUNCTION take_from_list_a(par_count int, par_array anyarray) IS
'Takes elements from "par_array" array while they satisfy condition calculated by "par_cond", returns array.
Parameter "par_cond" must contain SELECT query taking 2 parameters: $1 - index in array, $2 - array element; and returning boolean: TRUE - take element and continue, FALSE don''t take element and return current result.
If execution of "par_cond" returns NULL, an exception is rised.
postgres=# SELECT * FROM takewhile_from_list_a(''SELECT $1 >= ($2).a'', array[row(1,2,10),row(2,4,5),row(8,9,10),row(18,19,20)] :: lll[]);
 takewhile_from_list_a
------------------------
 {"(1,2,10)","(2,4,5)"}
(1 row)

Notice: Function uses EXECUTE. The important difference is that EXECUTE will re-plan the command on each execution, generating a plan that is specific to the current parameter values; whereas PL/pgSQL normally creates a generic plan and caches it for re-use. In situations where the best plan depends strongly on the parameter values, EXECUTE can be significantly faster; while when the plan is not sensitive to parameter values, re-planning will be a waste.
';

----------------------------------------------------------------------------
----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION drop_from_list_s(par_count integer, par_array anyarray) RETURNS SETOF anyelement
STRICT IMMUTABLE LANGUAGE plpgsql
AS $$
DECLARE lo integer; hi integer; r par_array%TYPE; idx integer; idx2 integer;
BEGIN   lo:= array_lower(par_array, 1); hi:= array_upper(par_array, 1);
        idx:= lo + par_count;
        idx2:= 1;
        WHILE idx <= hi LOOP
            r[idx2]:= par_array[idx];
            idx2:= idx2 + 1;
            idx := idx  + 1;
        END LOOP;
        RETURN QUERY SELECT * FROM unnest(r);
END;
$$;

COMMENT ON FUNCTION drop_from_list_s(par_count integer, par_array anyarray) IS
'Skips "par_count" elements from the beginning of the array and returns the rest. Returns set.
postgres=# SELECT * FROM drop_from_list_s(2, array[row(1,2,10),row(3,4,5),row(8,9,10),row(18,19,20)] :: lll[]);
 a  | b  | c
----+----+----
  8 |  9 | 10
 18 | 19 | 20
(2 rows)
';

----------------------------------------------------------------------------
----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION drop_from_list_a(par_count integer, par_array anyarray) RETURNS anyarray
STRICT IMMUTABLE LANGUAGE plpgsql
AS $$
DECLARE lo integer; hi integer; r par_array%TYPE; idx integer; idx2 integer;
BEGIN   lo:= array_lower(par_array, 1); hi:= array_upper(par_array, 1);
        idx:= lo + par_count;
        idx2:= 1;
        WHILE idx <= hi LOOP
            r[idx2]:= par_array[idx];
            idx2:= idx2 + 1;
            idx := idx  + 1;
        END LOOP;
        RETURN r;
END;
$$;

COMMENT ON FUNCTION drop_from_list_a(par_count integer, par_array anyarray) IS
'Skips "par_count" elements from the beginning of the array and returns the rest. Returns array.
postgres=# SELECT * FROM drop_from_list_a(2, array[row(1,2,10),row(3,4,5),row(8,9,10),row(18,19,20)] :: lll[]);
     drop_from_list_a
---------------------------
 {"(8,9,10)","(18,19,20)"}
(1 row)
';

----------------------------------------------------------------------------
----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION dropwhile_from_list_s(par_cond varchar, par_array anyarray) RETURNS SETOF anyelement
STRICT LANGUAGE plpgsql
AS $$
DECLARE i integer; l integer; r par_array%TYPE; b boolean; i2 integer;
BEGIN   i:= array_lower(par_array, 1); l:= array_upper(par_array, 1);
        b:= TRUE;
        i2:= 1;
        WHILE i <= l LOOP
            IF b THEN
                EXECUTE par_cond INTO b USING i, par_array[i];
                IF b IS NULL THEN RAISE EXCEPTION 'An error in "dropwhile_from_list_s"! Condition check returned NULL (at index %), which is not allowed!', i; END IF;
                IF NOT b THEN r[i2]:= par_array[i]; i2:= i2 + 1; END IF;
            ELSE
                r[i2]:= par_array[i]; i2:= i2 + 1;
            END IF;
            i:= i + 1;
        END LOOP;
        RETURN QUERY SELECT * FROM unnest(r);
END;
$$;

COMMENT ON FUNCTION dropwhile_from_list_s(par_cond varchar, par_array anyarray) IS
'Skips elements from "par_array" array, while they satisfy condition "par_cond". Rest of array is returned as set.
Parameter "par_cond" must contain SELECT query taking 2 parameters: $1 - index in array, $2 - array element; and returning boolean: TRUE - drop element, FALSE - stop checking and return rest of the array.
If execution of "par_cond" returns NULL, an exception is rised.
postgres=# SELECT * FROM dropwhile_from_list_s(''SELECT $1 >= ($2).a'', array[row(1,2,10),row(2,4,5),row(8,9,10),row(18,19,20)] :: lll[]);
 a  | b  | c
----+----+----
  8 |  9 | 10
 18 | 19 | 20
(2 rows)

Notice: Function uses EXECUTE. The important difference is that EXECUTE will re-plan the command on each execution, generating a plan that is specific to the current parameter values; whereas PL/pgSQL normally creates a generic plan and caches it for re-use. In situations where the best plan depends strongly on the parameter values, EXECUTE can be significantly faster; while when the plan is not sensitive to parameter values, re-planning will be a waste.
';

----------------------------------------------------------------------------
----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION dropwhile_from_list_a(par_cond varchar, par_array anyarray) RETURNS anyarray
STRICT LANGUAGE plpgsql
AS $$
DECLARE i integer; l integer; r par_array%TYPE; b boolean; i2 integer;
BEGIN   i:= array_lower(par_array, 1); l:= array_upper(par_array, 1);
        b:= TRUE;
        i2:= 1;
        WHILE i <= l LOOP
            IF b THEN
                EXECUTE par_cond INTO b USING i, par_array[i];
                IF b IS NULL THEN RAISE EXCEPTION 'An error in "dropwhile_from_list_a"! Condition check returned NULL (at index %), which is not allowed!', i; END IF;
                IF NOT b THEN r[i2]:= par_array[i]; i2:= i2 + 1; END IF;
            ELSE
                r[i2]:= par_array[i]; i2:= i2 + 1;
            END IF;
            i:= i + 1;
        END LOOP;
        RETURN r;
END;
$$;

COMMENT ON FUNCTION dropwhile_from_list_a(par_cond varchar, par_array anyarray) IS
'Skips elements from "par_array" array, while they satisfy condition "par_cond". Rest of array is returned.
Parameter "par_cond" must contain SELECT query taking 2 parameters: $1 - index in array, $2 - array element; and returning boolean: TRUE - drop element, FALSE - stop checking and return rest of the array.
If execution of "par_cond" returns NULL, an exception is rised.
postgres=# SELECT * FROM dropwhile_from_list_a(''SELECT $1 >= ($2).a'', array[row(1,2,10),row(2,4,5),row(8,9,10),row(18,19,20)] :: lll[]);
   dropwhile_from_list_a
---------------------------
 {"(8,9,10)","(18,19,20)"}
(1 row)

Notice: Function uses EXECUTE. The important difference is that EXECUTE will re-plan the command on each execution, generating a plan that is specific to the current parameter values; whereas PL/pgSQL normally creates a generic plan and caches it for re-use. In situations where the best plan depends strongly on the parameter values, EXECUTE can be significantly faster; while when the plan is not sensitive to parameter values, re-planning will be a waste.
';

----------------------------------------------------------------------------
----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION split_at(par_position integer, par_array anyarray) RETURNS RECORD
STRICT IMMUTABLE LANGUAGE plpgsql
AS $$
DECLARE i integer; l integer; r1 par_array%TYPE; r2 par_array%TYPE; first_chunk boolean; switch_ boolean; i2 integer;
        r RECORD;
BEGIN   i:= array_lower(par_array, 1); l:= array_upper(par_array, 1);
        first_chunk:= TRUE;
        i2:= 1;
        WHILE i <= l LOOP
            IF first_chunk THEN
                switch_:= first_chunk AND (i > par_position);
                first_chunk:= NOT switch_;
                IF NOT first_chunk THEN i2:= 1; END IF;
            END IF;
            IF first_chunk THEN
                r1[i2]:= par_array[i];
            ELSE
                r2[i2]:= par_array[i];
            END IF;
            i := i  + 1;
            i2:= i2 + 1;
        END LOOP;
        r:= ROW(r1, r2);
        RETURN r;
END;
$$;

COMMENT ON FUNCTION split_at(par_position integer, par_array anyarray) IS
'Splits an array into two parts.
postgres=# SELECT split_at(2, array[row(1,2,10),row(2,4,5),row(8,9,10),row(18,19,20)] :: lll[]);
                            split_at
----------------------------------------------------------------
 ("{""(1,2,10)"",""(2,4,5)""}","{""(8,9,10)"",""(18,19,20)""}")
(1 row)
';

----------------------------------------------------------------------------
----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION span_list(par_cond varchar, par_array anyarray) RETURNS RECORD
STRICT LANGUAGE plpgsql
AS $$
DECLARE i integer; l integer; r1 par_array%TYPE; r2 par_array%TYPE; first_chunk boolean; switch_ boolean; i2 integer;
        r RECORD; cc boolean;
BEGIN   i:= array_lower(par_array, 1); l:= array_upper(par_array, 1);
        first_chunk:= TRUE;
        i2:= 1;
        WHILE i <= l LOOP
            IF first_chunk THEN
                EXECUTE par_cond INTO cc USING i, par_array[i];
                IF cc IS NULL THEN RAISE EXCEPTION 'An error in "span_list"! Condition check returned NULL (at index %), which is not allowed!', i; END IF;
                switch_:= first_chunk AND NOT cc;
                first_chunk:= NOT switch_;
                IF NOT first_chunk THEN i2:= 1; END IF;
            END IF;
            IF first_chunk THEN
                r1[i2]:= par_array[i];
            ELSE
                r2[i2]:= par_array[i];
            END IF;
            i := i  + 1;
            i2:= i2 + 1;
        END LOOP;
        r:= ROW(r1, r2);
        RETURN r;
END;
$$;

COMMENT ON FUNCTION span_list(par_cond varchar, par_array anyarray) IS
'Splits an array into two parts. While "par_cond" condition is met 1st resulting array part is filled; once condition check returns FALSE second part filling starts.
Parameter "par_cond" must contain SELECT query taking 2 parameters: $1 - index in array, $2 - array element; and returning boolean: TRUE - drop element, FALSE - stop checking and return rest of the array.
postgres=# SELECT span_list(''SELECT $1 >= ($2).a'', array[row(1,2,10),row(2,4,5),row(8,9,10),row(18,19,20)] :: lll[]);
                           span_list
----------------------------------------------------------------
 ("{""(1,2,10)"",""(2,4,5)""}","{""(8,9,10)"",""(18,19,20)""}")
(1 row)

Notice: Function uses EXECUTE. The important difference is that EXECUTE will re-plan the command on each execution, generating a plan that is specific to the current parameter values; whereas PL/pgSQL normally creates a generic plan and caches it for re-use. In situations where the best plan depends strongly on the parameter values, EXECUTE can be significantly faster; while when the plan is not sensitive to parameter values, re-planning will be a waste.
';

----------------------------------------------------------------------------
----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION break_list(varchar, anyarray) RETURNS RECORD
STRICT LANGUAGE SQL
AS $$
        SELECT span_list('SELECT NOT (' || $1 || ')', $2);
$$;

COMMENT ON FUNCTION break_list(varchar, anyarray) IS
'=span_list(''SELECT NOT ('' || $1 || '')'', $2)
postgres=# SELECT break_list(''SELECT $1 < ($2).a'', array[row(1,2,10),row(2,4,5),row(8,9,10),row(18,19,20)] :: lll[]);
                           break_list
----------------------------------------------------------------
 ("{""(1,2,10)"",""(2,4,5)""}","{""(8,9,10)"",""(18,19,20)""}")
(1 row)

Notice: Function uses EXECUTE. The important difference is that EXECUTE will re-plan the command on each execution, generating a plan that is specific to the current parameter values; whereas PL/pgSQL normally creates a generic plan and caches it for re-use. In situations where the best plan depends strongly on the parameter values, EXECUTE can be significantly faster; while when the plan is not sensitive to parameter values, re-planning will be a waste.
';

----------------------------------------------------------------------------
----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION in_list(anyelement,anyarray) RETURNS boolean
STRICT LANGUAGE SQL
AS $$
        SELECT idx_in_list($2, $1) IS NOT NULL;
$$;

COMMENT ON FUNCTION in_list(anyelement,anyarray) IS
'=idx_in_list($2, $1) IS NOT NULL
postgres=# select in_list(row(3,4,8) :: lll, array[row(1,2,3),row(3,4,5),row(8,9
,10)] :: lll[]);
 in_list
---------
 f
(1 row)
';

----------------------------------------------------------------------------
----------------------------------------------------------------------------
----------------------------------------------------------------------------
----------------------------------------------------------------------------
-- Taken from "PostgreSQL SQL Tricks" (http://www.postgres.cz/index.php/PostgreSQL_SQL_Tricks)


CREATE OR REPLACE FUNCTION eval_1(varchar) RETURNS RECORD
STRICT LANGUAGE plpgsql
AS $$
DECLARE result RECORD;
BEGIN EXECUTE $1 INTO result; RETURN result; END; $$;

----------------------------------------------------------------------------
----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION eval_s(varchar) RETURNS SETOF RECORD
STRICT LANGUAGE plpgsql
AS $$ BEGIN RETURN QUERY EXECUTE $1; END; $$;

----------------------------------------------------------------------------
----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION eval_t(varchar) RETURNS varchar
STRICT LANGUAGE plpgsql
AS $$
DECLARE result varchar;
BEGIN EXECUTE $1 INTO result; RETURN result; END; $$;

----------------------------------------------------------------------------
----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION defaults(
        table_name regclass
      , OUT attname name
      , OUT type varchar
      , OUT default_val varchar
      ) RETURNS SETOF RECORD
STRICT LANGUAGE SQL
AS $$
        SELECT a.attname,
               pg_catalog.format_type(a.atttypid, a.atttypmod),
               (SELECT eval_t('SELECT ' || pg_catalog.pg_get_expr(d.adbin, d.adrelid))
                   FROM pg_catalog.pg_attrdef d
                  WHERE d.adrelid = a.attrelid AND d.adnum = a.attnum AND a.atthasdef)
           FROM pg_catalog.pg_attribute a
          WHERE a.attrelid = $1::oid AND a.attnum > 0 AND NOT a.attisdropped
          ORDER BY a.attnum
$$;

----------------------------------------------------------------------------
----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION sort(anyarray) RETURNS anyarray LANGUAGE SQL AS $$
        SELECT array(SELECT * FROM unnest($1) ORDER BY 1);
$$;


----------------------------------------------------------------------------
----------------------------------------------------------------------------
----------------------------------------------------------------------------
----------------------------------------------------------------------------

-- Service functions:

GRANT EXECUTE ON FUNCTION enter_schema_namespace(par_shema_name varchar) TO PUBLIC;
GRANT EXECUTE ON FUNCTION leave_schema_namespace(par_prev_state t_namespace_info) TO PUBLIC;
GRANT EXECUTE ON FUNCTION __watch(par_tag varchar, par_str anyelement) TO PUBLIC;
GRANT EXECUTE ON FUNCTION __halt(par_tag varchar, par_str anyelement) TO PUBLIC;


-- Functions written by Marcos Ortíz Valmaseda, Pavel Stehule:
-- "I wrote some perhaps useful functions for PostgreSQL. This project collect it and allows easy using of these functions."
-- (licensed under BSD License)

GRANT EXECUTE ON FUNCTION sprintf(fmt text, VARIADIC args "any") TO PUBLIC;
GRANT EXECUTE ON FUNCTION sprintf(fmt text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION format(fmt text, VARIADIC args "any") TO PUBLIC;
GRANT EXECUTE ON FUNCTION format(fmt text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION concat(VARIADIC args "any") TO PUBLIC;
GRANT EXECUTE ON FUNCTION concat_ws(separator text, VARIADIC args "any") TO PUBLIC;
GRANT EXECUTE ON FUNCTION concat_js(VARIADIC args "any") TO PUBLIC;
GRANT EXECUTE ON FUNCTION concat_sql(VARIADIC args "any") TO PUBLIC;
GRANT EXECUTE ON FUNCTION rvrs(str text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION left(str text, n int) TO PUBLIC;
GRANT EXECUTE ON FUNCTION right(str text, n int) TO PUBLIC;
GRANT EXECUTE ON FUNCTION chars_to_array(chars text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION next_day(d date, dow text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION last_day(d date) TO PUBLIC;


-- Functions inspired by similar from Haskell:

GRANT EXECUTE ON FUNCTION in_list(anyelement,anyarray) TO PUBLIC;
GRANT EXECUTE ON FUNCTION break_list(varchar, anyarray) TO PUBLIC;
GRANT EXECUTE ON FUNCTION span_list(par_cond varchar, par_array anyarray) TO PUBLIC;
GRANT EXECUTE ON FUNCTION split_at(par_position integer, par_array anyarray) TO PUBLIC;
GRANT EXECUTE ON FUNCTION dropwhile_from_list_a(par_cond varchar, par_array anyarray) TO PUBLIC;
GRANT EXECUTE ON FUNCTION dropwhile_from_list_s(par_cond varchar, par_array anyarray) TO PUBLIC;
GRANT EXECUTE ON FUNCTION drop_from_list_a(par_count integer, par_array anyarray) TO PUBLIC;
GRANT EXECUTE ON FUNCTION drop_from_list_s(par_count integer, par_array anyarray) TO PUBLIC;
GRANT EXECUTE ON FUNCTION take_from_list_a(par_count int, par_array anyarray) TO PUBLIC;
GRANT EXECUTE ON FUNCTION take_from_list_s(par_count int, par_array anyarray) TO PUBLIC;
GRANT EXECUTE ON FUNCTION take_from_list_a(par_count int, par_array anyarray) TO PUBLIC;
GRANT EXECUTE ON FUNCTION take_from_list_s(par_count int, par_array anyarray) TO PUBLIC;
GRANT EXECUTE ON FUNCTION fp_replicate_a(par_count int, par_elem anyelement) TO PUBLIC;
GRANT EXECUTE ON FUNCTION fp_replicate_s(par_count int, par_elem anyelement) TO PUBLIC;
GRANT EXECUTE ON FUNCTION maxim(anyelement, anyelement) TO PUBLIC;
GRANT EXECUTE ON FUNCTION minim(anyelement, anyelement) TO PUBLIC;
GRANT EXECUTE ON FUNCTION fp_foldr(par_arr anyarray, par_fun varchar, par_accum_initfun varchar, par_stoponnull_dowe boolean) TO PUBLIC;
GRANT EXECUTE ON FUNCTION fp_foldl(par_accum_initfun varchar, par_fun varchar, par_arr anyarray, par_stoponnull_dowe boolean) TO PUBLIC;
GRANT EXECUTE ON FUNCTION fp_map(par_arr anyarray, par_fun varchar, par_keepnulls_dowe boolean) TO PUBLIC;
GRANT EXECUTE ON FUNCTION fp_monoid_foldr(par_arr anyarray, par_fun varchar, par_accum anyelement, par_stoponnull_dowe boolean) TO PUBLIC;
GRANT EXECUTE ON FUNCTION fp_monoid_foldl(par_accum anyelement, par_fun varchar, par_arr anyarray, par_stoponnull_dowe boolean) TO PUBLIC;
GRANT EXECUTE ON FUNCTION fp_monoid_map_s(par_arr anyarray, par_fun varchar, par_keepnulls_dowe boolean) TO PUBLIC;
GRANT EXECUTE ON FUNCTION fp_monoid_map_a(par_arr anyarray, par_fun varchar, par_keepnulls_dowe boolean) TO PUBLIC;
GRANT EXECUTE ON FUNCTION explode_array_wi(anyarray) TO PUBLIC;
GRANT EXECUTE ON FUNCTION first_in_list_to_satisfy(par_arr anyarray, par_crit varchar) TO PUBLIC;
GRANT EXECUTE ON FUNCTION idx_in_list(par_arr anyarray, par_elem anyelement) TO PUBLIC;


-- Taken from "PostgreSQL SQL Tricks" (http://www.postgres.cz/index.php/PostgreSQL_SQL_Tricks)

GRANT EXECUTE ON FUNCTION defaults(
        table_name regclass
      , OUT attname name
      , OUT type varchar
      , OUT default_val varchar
      ) TO PUBLIC;
GRANT EXECUTE ON FUNCTION sort(anyarray)  TO PUBLIC;
GRANT EXECUTE ON FUNCTION eval_t(varchar)  TO PUBLIC;
GRANT EXECUTE ON FUNCTION eval_s(varchar)  TO PUBLIC;
GRANT EXECUTE ON FUNCTION eval_1(varchar) TO PUBLIC;

