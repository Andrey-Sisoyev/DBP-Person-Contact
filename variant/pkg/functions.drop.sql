-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For information about license see COPYING file in the root directory of current nominal package

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- (1) case sensetive (2) postgres lowercases real names
\c <<$db_name$>> user_<<$app_name$>>_owner

SET search_path TO sch_<<$app_name$>>, public; -- sets only for current session

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

-- DROP FUNCTION IF EXISTS ...
-- DROP TYPE     IF EXISTS ...

\i contacts_instances/main.drop.sql

-- Referncing functions:

DROP FUNCTION IF EXISTS mk_person_language_construction_input(par_lng_code t_code_key_by_lng, par_lng_skill integer, par_lng_personal_priority integer);
DROP FUNCTION IF EXISTS mk_contact_construction_input(par_contact_type t_code_key_by_lng, par_contact_personal_priority integer, par_contact_constraints varchar);

-- Lookup functions:

DROP FUNCTION IF EXISTS find_person_by_contact(par_contact_id integer);
DROP FUNCTION IF EXISTS find_contacts_of_person(par_person_id integer);
DROP FUNCTION IF EXISTS find_persons_by_name(par_lng_codekeyl t_code_key_by_lng, par_name_regexp varchar, par_regexp_match_op posix_regexp_match_op);

-- Administration functions:

DROP FUNCTION IF EXISTS new_abstract_contact(par_person_id integer, par_contact_ci contact_construction_input, par_contact_names name_construction_input[]);
DROP FUNCTION IF EXISTS add_names_to_contact(par_contact_id integer, par_contact_names name_construction_input[]);
DROP FUNCTION IF EXISTS new_person(par_person_type t_code_key_by_lng, par_names name_construction_input[], par_languages t_person_language_construction_input[]);
DROP FUNCTION IF EXISTS add_languages_to_person(par_person_id integer, par_languages t_person_language_construction_input[]);
DROP FUNCTION IF EXISTS add_names_to_person(par_person_id integer, par_names name_construction_input[]);


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

DROP TYPE IF EXISTS contact_construction_input;
DROP TYPE IF EXISTS t_person_language_construction_input;
DROP TYPE IF EXISTS posix_regexp_match_op;

