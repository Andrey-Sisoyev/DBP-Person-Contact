-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- (1) case sensetive (2) postgres lowercases real names
\c <<$db_name$>> user_<<$app_name$>>_owner

SET search_path TO sch_<<$app_name$>>, public; -- sets only for current session

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Lookup functions:

CREATE OR REPLACE FUNCTION find_person_by_contact(par_contact_id integer) RETURNS integer AS $$
        SELECT p.person_id
        FROM sch_<<$app_name$>>.persons  AS p
           , sch_<<$app_name$>>.contacts AS c
        WHERE c.contact_id = $1
          AND p.person_id = c.person_id;
$$ LANGUAGE SQL;

COMMENT ON FUNCTION find_person_by_contact(par_contact_id integer) IS
'Returns person ID.';

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION find_contacts_of_person(par_person_id integer) RETURNS SETOF contacts AS $$
        SELECT c.*
        FROM sch_<<$app_name$>>.contacts AS c
        WHERE c.person_id = $1;
$$ LANGUAGE SQL;

-------------------------------------------------------------------------------

CREATE TYPE posix_regexp_match_op AS ENUM ('~', '~*', '!~', '!~*');

CREATE OR REPLACE FUNCTION find_persons_by_name(
        par_lng_codekeyl    t_code_key_by_lng
      , par_name_regexp     varchar
      , par_regexp_match_op posix_regexp_match_op
      ) RETURNS SETOF persons AS $$
DECLARE
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        CASE par_regexp_match_op
                WHEN '~' THEN
                        RETURN QUERY
                                SELECT p.*
                                FROM persons AS p
                                   , persons_names AS pn
                                WHERE p.person_id = pn. person_id
                                  AND pn.name ~ par_name_regexp
                                  AND (  codekeyl_type(par_lng_codekeyl) = 'undef'
                                      OR pn.lng_of_name = code_id_of( FALSE, generalize_codekeyl_wcf(make_codekey_bystr('Languages'), par_lng_codekeyl))
                                      );
                WHEN '~*' THEN
                        RETURN QUERY
                                SELECT p.*
                                FROM persons AS p
                                   , persons_names AS pn
                                WHERE p.person_id = pn. person_id
                                  AND pn.name ~* par_name_regexp
                                  AND (  codekeyl_type(par_lng_codekeyl) = 'undef'
                                      OR pn.lng_of_name = code_id_of( FALSE, generalize_codekeyl_wcf(make_codekey_bystr('Languages'), par_lng_codekeyl))
                                      );
                WHEN '!~' THEN
                        RETURN QUERY
                                SELECT p.*
                                FROM persons AS p
                                   , persons_names AS pn
                                WHERE p.person_id = pn. person_id
                                  AND pn.name !~ par_name_regexp
                                  AND (  codekeyl_type(par_lng_codekeyl) = 'undef'
                                      OR pn.lng_of_name = code_id_of( FALSE, generalize_codekeyl_wcf(make_codekey_bystr('Languages'), par_lng_codekeyl))
                                      );
                WHEN '!~*' THEN
                        RETURN QUERY
                                SELECT p.*
                                FROM persons AS p
                                   , persons_names AS pn
                                WHERE p.person_id = pn. person_id
                                  AND pn.name !~* par_name_regexp
                                  AND (  codekeyl_type(par_lng_codekeyl) = 'undef'
                                      OR pn.lng_of_name = code_id_of( FALSE, generalize_codekeyl_wcf(make_codekey_bystr('Languages'), par_lng_codekeyl))
                                      );
                ELSE
                        RAISE EXCEPTION 'An error occurred in function "find_persons_by_name"! Unsupported value of "par_regexp_match_op" argument: "%"!', par_regexp_match_op;
        END CASE;

        PERFORM leave_schema_namespace(namespace_info);
        RETURN;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION find_persons_by_name(
        par_lng_codekeyl    t_code_key_by_lng
      , par_name_regexp     varchar
      , par_regexp_match_op posix_regexp_match_op
      ) IS
'If you specify NULL (btw, use make_codekeyl_null()) for field "par_lng_codekeyl", then function will search in all languages.

Manual on usage of POSIX regexps in PostgreSQL (v8.4):
http://www.postgresql.org/docs/8.4/interactive/functions-matching.html
';

-------------------------------------------------------------
-------------------------------------------------------------
-------------------------------------------------------------
-- Administrative functions:

CREATE OR REPLACE FUNCTION add_names_to_person(
        par_person_id integer
      , par_names     name_construction_input[]
      ) RETURNS integer AS $$
DECLARE
        cnt1 integer;
        cnt2 integer;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
        dflt_lng_c_id integer;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        FOR cnt1 IN
                SELECT 1 FROM unnest(par_names) AS inp WHERE codekeyl_type(inp.lng) = 'undef' LIMIT 1
        LOOP
                dflt_lng_c_id:= codifier_default_code(FALSE, make_codekeyl_bystr('Languages'));
        END LOOP;

        INSERT INTO persons_names (person_id, lng_of_name, name, entity, description)
                SELECT par_person_id, v.lng_of_name, v.name, v.entity, v.description
                FROM (SELECT CASE WHEN codekeyl_type(inp.lng) != 'undef'
                                  THEN code_id_of( FALSE, generalize_codekeyl_wcf(make_codekey_bystr('Languages'), inp.lng))
                                  ELSE dflt_lng_c_id
                             END AS lng_of_name
                           , inp.name
                           , code_id_of( FALSE, generalize_codekeyl_wcf(make_codekey_bystr('Entities'), inp.entity)) AS entity
                           , inp.description
                      FROM unnest(par_names) AS inp
                      WHERE codekeyl_type(inp.entity) != 'undef'
                      ) AS v;
        GET DIAGNOSTICS cnt1 = ROW_COUNT;

        -- it's a pity Postgres has poor semantics for inserting DEFAULT... well, it's not a big deal though
        INSERT INTO persons_names (person_id, lng_of_name, name, description)
                SELECT par_person_id, v.lng_of_name, v.name, v.description
                FROM (SELECT CASE WHEN codekeyl_type(inp.lng) != 'undef'
                                  THEN code_id_of( FALSE, generalize_codekeyl_wcf(make_codekey_bystr('Languages'), inp.lng))
                                  ELSE dflt_lng_c_id
                             END AS lng_of_name
                           , inp.name
                           , inp.description
                      FROM unnest(par_names) AS inp
                      WHERE codekeyl_type(inp.entity) = 'undef'
                      ) AS v;
        GET DIAGNOSTICS cnt2 = ROW_COUNT;

        PERFORM leave_schema_namespace(namespace_info);
        RETURN (cnt1 + cnt2);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION add_names_to_person(
        par_person_id integer
      , par_names     name_construction_input[]
      ) IS
'Returns count of rows inserted.';

-------------------------------------------------------------------------------

CREATE TYPE t_person_language_construction_input AS (
          lng_code              t_code_key_by_lng
        , lng_skill             integer
        , lng_personal_priority integer
        );

CREATE OR REPLACE FUNCTION mk_person_language_construction_input(
          par_lng_code              t_code_key_by_lng
        , par_lng_skill             integer
        , par_lng_personal_priority integer
        ) RETURNS t_person_language_construction_input AS $$
        SELECT ROW ($1, $2, $3) :: t_person_language_construction_input;
$$ LANGUAGE SQL;

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION add_languages_to_person(
        par_person_id integer
      , par_languages t_person_language_construction_input[]
      ) RETURNS integer AS $$
DECLARE
        p_id integer;
        cnt integer;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        INSERT INTO persons_languages (
                        person_id
                      , lng_code
                      , lng_skill
                      , lng_personal_priority
                      )
                SELECT par_person_id AS person_id
                     , code_id_of( FALSE, generalize_codekeyl_wcf(make_codekey_bystr('Languages'), pl.lng_code)) AS lng_code
                     , pl.lng_skill
                     , pl.lng_personal_priority
                FROM unnest(par_languages) AS pl;
        GET DIAGNOSTICS cnt = ROW_COUNT;

        PERFORM leave_schema_namespace(namespace_info);
        RETURN cnt;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION add_languages_to_person(
        par_person_id integer
      , par_languages t_person_language_construction_input[]
      ) IS
'Returns count of rows inserted.';

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION new_person(
        par_person_type t_code_key_by_lng
      , par_names       name_construction_input[]
      , par_languages   t_person_language_construction_input[]
      ) RETURNS integer AS $$
DECLARE
        p_id integer;
        cnt1 integer;
        cnt2 integer;
        cnt3 integer;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        INSERT INTO persons (person_type) VALUES (code_id_of( FALSE, generalize_codekeyl_wcf(make_codekey_bystr('Persons types'), par_person_type)))
        RETURNING person_id INTO p_id;
        GET DIAGNOSTICS cnt1 = ROW_COUNT;

        cnt2:= add_languages_to_person(
                 p_id
               , par_languages
               );

        cnt3:= add_names_to_person(
                 p_id
               , par_names
               );

        PERFORM leave_schema_namespace(namespace_info);
        RETURN p_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION new_person(
        par_person_type t_code_key_by_lng
      , par_names       name_construction_input[]
      , par_languages   t_person_language_construction_input[]
      ) IS
'Returns person ID';

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION add_names_to_contact(par_contact_id integer, par_contact_names name_construction_input[]) RETURNS integer AS $$
DECLARE
        cnt1 integer;
        cnt2 integer;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
        dflt_lng_c_id integer;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        FOR cnt1 IN
                SELECT 1 FROM unnest(par_contact_names) AS inp WHERE codekeyl_type(inp.lng) = 'undef' LIMIT 1
        LOOP
                dflt_lng_c_id:= codifier_default_code(FALSE, make_codekeyl_bystr('Languages'));
        END LOOP;

        INSERT INTO contacts_names (contact_id, lng_of_name, name, entity, description)
                SELECT par_contact_id, v.lng_of_name, v.name, v.entity, v.description
                FROM (SELECT CASE WHEN codekeyl_type(inp.lng) != 'undef'
                                  THEN code_id_of( FALSE, generalize_codekeyl_wcf(make_codekey_bystr('Languages'), inp.lng))
                                  ELSE dflt_lng_c_id
                             END AS lng_of_name
                           , inp.name
                           , code_id_of( FALSE, generalize_codekeyl_wcf(make_codekey_bystr('Entities'), inp.entity)) AS entity
                           , inp.description
                      FROM unnest(par_contact_names) AS inp
                      WHERE codekeyl_type(inp.entity) != 'undef'
                      ) AS v;
        GET DIAGNOSTICS cnt1 = ROW_COUNT;

        -- it's a pity Postgres has poor semantics for inserting DEFAULT... well, it's not a big deal though
        INSERT INTO contacts_names (contact_id, lng_of_name, name, description)
                SELECT par_contact_id, v.lng_of_name, v.name, v.description
                FROM (SELECT CASE WHEN codekeyl_type(inp.lng) != 'undef'
                                  THEN code_id_of( FALSE, generalize_codekeyl_wcf(make_codekey_bystr('Languages'), inp.lng))
                                  ELSE dflt_lng_c_id
                             END AS lng_of_name
                           , inp.name
                           , inp.description
                      FROM unnest(par_contact_names) AS inp
                      WHERE codekeyl_type(inp.entity) = 'undef'
                      ) AS v;
        GET DIAGNOSTICS cnt2 = ROW_COUNT;

        PERFORM leave_schema_namespace(namespace_info);
        RETURN (cnt1 + cnt2);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION add_names_to_contact(par_contact_id integer, par_contact_names name_construction_input[]) IS
'Returns count of rows inserted.';

-------------------------------------------------------------------------------

CREATE TYPE contact_construction_input AS (
         contact_type              t_code_key_by_lng
       , contact_personal_priority integer
       , contact_constraints       varchar
       );

CREATE OR REPLACE FUNCTION mk_contact_construction_input(
         par_contact_type              t_code_key_by_lng
       , par_contact_personal_priority integer
       , par_contact_constraints       varchar
       ) RETURNS contact_construction_input AS $$
        SELECT ROW ($1, $2, $3) :: contact_construction_input;
$$ LANGUAGE SQL;

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION new_abstract_contact(par_person_id integer, par_contact_ci contact_construction_input, par_contact_names name_construction_input[]) RETURNS integer AS $$
DECLARE
        c_id integer;
        cnt1 integer;
        cnt2 integer;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        INSERT INTO contacts (
                        person_id
                      , contact_type
                      , contact_personal_priority
                      , contact_constraints
                      )
               VALUES ( par_person_id
                      , code_id_of( FALSE, generalize_codekeyl_wcf(make_codekey_bystr('Personal contacts types'), par_contact_ci.contact_type))
                      , par_contact_ci.contact_personal_priority
                      , par_contact_ci.contact_constraints
                      )
        RETURNING contact_id INTO c_id;
        GET DIAGNOSTICS cnt1 = ROW_COUNT;

        cnt2:= add_names_to_contact(c_id, par_contact_names);

        PERFORM leave_schema_namespace(namespace_info);
        RETURN c_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION new_abstract_contact(par_person_id integer, par_contact_ci contact_construction_input, par_contact_names name_construction_input[]) IS
'Returns contact ID.';

-------------------------------------------------------------------------------

-- Referncing functions:

GRANT EXECUTE ON FUNCTION mk_person_language_construction_input(par_lng_code t_code_key_by_lng, par_lng_skill integer, par_lng_personal_priority integer)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION mk_contact_construction_input(par_contact_type t_code_key_by_lng, par_contact_personal_priority integer, par_contact_constraints varchar)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;

-- Lookup functions:

GRANT EXECUTE ON FUNCTION find_person_by_contact(par_contact_id integer)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION find_contacts_of_person(par_person_id integer)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION find_persons_by_name(par_lng_codekeyl t_code_key_by_lng, par_name_regexp varchar, par_regexp_match_op posix_regexp_match_op)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;

-- Administration functions:

GRANT EXECUTE ON FUNCTION new_abstract_contact(par_person_id integer, par_contact_ci contact_construction_input, par_contact_names name_construction_input[])TO user_<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION add_names_to_contact(par_contact_id integer, par_contact_names name_construction_input[])TO user_<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION new_person(par_person_type t_code_key_by_lng, par_names name_construction_input[], par_languages t_person_language_construction_input[])TO user_<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION add_languages_to_person(par_person_id integer, par_languages t_person_language_construction_input[])TO user_<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION add_names_to_person(par_person_id integer, par_names name_construction_input[])TO user_<<$app_name$>>_data_admin;

\i contacts_instances/main.init.sql