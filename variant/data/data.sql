-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo data.sql
\c <<$db_name$>> user_<<$app_name$>>_owner
SET search_path TO sch_<<$app_name$>>, public;

-- INSERT INTO ...

ALTER SEQUENCE  persons_ids_seq RESTART WITH 1;
ALTER SEQUENCE contacts_ids_seq RESTART WITH 1;

-- you don't have to keep all this data in your application, - it's here
-- just as a general case and for an example of API use

SELECT new_person(
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

SELECT new_abstract_contact(
                1
              , mk_contact_construction_input(
                         make_codekeyl_bystr('e-mail')
                       , 0
                       , 'Don''t send me ads here, if you dont want to get into the spammers-list.'
                       )
              , ARRAY [ mk_name_construction_input(
                                make_codekeyl_bystr('eng')
                              , 'Andrey Sisoyev e-mail box.'
                              , make_codekeyl_null()
                              , 'Andrey Sisoyev e-mail box for professional contacts.'
                              )
                      ]
              );

SELECT instaniate_contact_as_email(
                1
              , ROW('andrejs.sisojevs@nextmail.ru') :: contact_email_construction_input
              );

ALTER SEQUENCE  persons_ids_seq RESTART WITH 100;
ALTER SEQUENCE contacts_ids_seq RESTART WITH 100;