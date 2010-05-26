-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\c <<$db_name$>> user_db<<$db_name$>>_app<<$app_name$>>_owner
SET search_path TO sch_<<$app_name$>>, comn_funs, public;
\set ECHO none

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> data.init.sql [BEGIN]

\set ECHO none

-------------------
-------------------

CREATE OR REPLACE FUNCTION pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__initial_data_delete__() RETURNS integer
LANGUAGE plpgsql
SET search_path TO sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE rows_cnt integer;
BEGIN
        DELETE FROM persons WHERE person_id IN (1,2,3,4);
        -- procedure body
        RETURN 0;
END;
$$;

COMMENT ON FUNCTION pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__initial_data_delete__() IS
'Deletes initial data from the database package "<<$pkg.name$>>" (version "<<$pkg.ver$>>").
This data is considered to be a part of the package.
Data is assumed to be inserted using "pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__initial_data_insert__()" function.
';

-------------------
-------------------

CREATE OR REPLACE FUNCTION pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__initial_data_insert__() RETURNS integer
LANGUAGE plpgsql
SET search_path TO sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE rows_cnt integer;
BEGIN
        PERFORM pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__initial_data_delete__();
        -----------------------------------------------
        EXECUTE 'ALTER SEQUENCE  persons_ids_seq RESTART WITH 1';
        EXECUTE 'ALTER SEQUENCE contacts_ids_seq RESTART WITH 1';

        -- you don't have to keep all this data in your application, - it's here
        -- just as a general case and for an example of API use

        PERFORM new_person(
                        make_codekeyl_bystr('human')
                      , ARRAY [ mk_name_construction_input(
                                        make_codekeyl_bystr('eng')
                                      , 'Andrey Sisoyev'
                                      , make_codekeyl_null()
                                      , 'Author of "Person-Contact" and "Codifier" DB packages.'
                                      )
                              ] :: name_construction_input[]
                      , ARRAY [ mk_person_language_construction_input(
                                        make_codekeyl_bystr('eng')
                                      , 30
                                      , 0
                                      )
                              , mk_person_language_construction_input(
                                        make_codekeyl_bystr('rus')
                                      , 60
                                      , 50
                                      )
                              ] :: t_person_language_construction_input[]
                      )
             , new_person(
                        make_codekeyl_bystr('organization')
                      , ARRAY [ mk_name_construction_input(
                                        make_codekeyl_bystr('eng')
                                      , '<input name of the owner of this system here>'
                                      , make_codekeyl_null()
                                      , 'Owner of this system.'
                                      )
                              ] :: name_construction_input[]
                      , ARRAY [ mk_person_language_construction_input(
                                        make_codekeyl_bystr('eng')
                                      , NULL :: integer
                                      , 0
                                      )
                              ] :: t_person_language_construction_input[]
                      )
             , new_person(
                        make_codekeyl_bystr('human')
                      , ARRAY [ mk_name_construction_input(
                                        make_codekeyl_bystr('eng')
                                      , '<input name of technical admin of this system here>'
                                      , make_codekeyl_null()
                                      , 'Technical admin of this system.'
                                      )
                              ] :: name_construction_input[]
                      , ARRAY [ mk_person_language_construction_input(
                                        make_codekeyl_bystr('eng')
                                      , NULL :: integer
                                      , 0
                                      )
                              ] :: t_person_language_construction_input[]
                      )
             , new_person(
                        make_codekeyl_bystr('human')
                      , ARRAY [ mk_name_construction_input(
                                        make_codekeyl_bystr('eng')
                                      , '<input name of data admin of this system here>'
                                      , make_codekeyl_null()
                                      , 'Data admin of this system.'
                                      )
                              ] :: name_construction_input[]
                      , ARRAY [ mk_person_language_construction_input(
                                        make_codekeyl_bystr('eng')
                                      , NULL :: integer
                                      , 0
                                      )
                              ] :: t_person_language_construction_input[]
                      )
             ;

        PERFORM new_abstract_contact(
                        1
                      , mk_contact_construction_input(
                                 make_codekeyl_bystr('e-mail')
                               , 0
                               , 'Please don''t send me spam here!'
                               )
                      , ARRAY [ mk_name_construction_input(
                                        make_codekeyl_bystr('eng')
                                      , 'Andrey Sisoyev e-mail box.'
                                      , make_codekeyl_null()
                                      , 'Andrey Sisoyev e-mail box for professional contacts.'
                                      )
                              ]
                      );

        PERFORM instaniate_contact_as_email(
                        1
                      , ROW('andrejs.sisojevs@nextmail.ru') :: contact_email_construction_input
                      );

        EXECUTE 'ALTER SEQUENCE  persons_ids_seq RESTART WITH 100';
        EXECUTE 'ALTER SEQUENCE contacts_ids_seq RESTART WITH 100';
        -----------------------------------------------
        RETURN 0;
END;
$$;

COMMENT ON FUNCTION pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__initial_data_insert__() IS
'Inserts initial data into the database package "<<$pkg.name$>>" (version "<<$pkg.ver$>>").
This data is considered to be a part of the package.
Data is assumed to be possible to delete the initial data using "pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__initial_data_delete__()" function.
Also, this deletion function is called in the beginning of inserting function.
';

-------------------
-------------------

SELECT set_config('client_min_messages', 'NOTICE', FALSE);

\set ECHO queries
SELECT pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__initial_data_insert__();
\set ECHO none

-------------------
-------------------

\echo NOTICE >>>>> data.init.sql [END]