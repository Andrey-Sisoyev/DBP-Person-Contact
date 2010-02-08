-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\c <<$db_name$>> user_<<$app_name$>>_data_admin

SET search_path TO sch_<<$app_name$>>, public;
\set ECHO queries
SELECT set_config('client_min_messages', 'NOTICE', FALSE);

\echo WARNING!!! This tester is not guaranteed to be safe for user data - do not apply it where user already defined it's codes!!

SELECT * FROM persons;
SELECT * FROM contacts;
SELECT * FROM contacts__emails;

\echo --------------------------------------------------------------
\echo Creating test case.
\echo

SELECT new_person(
                make_codekeyl_bystr('human') -- type of person
              , ARRAY [ mk_name_construction_input(
                                make_codekeyl_bystr('eng') -- language of name
                              , 'Test person 1234567890'   -- name
                              , make_codekeyl_null()       -- entity (will be set automatically to default, which for persons is "person")
                              , 'description...'           -- description
                              )
                      , mk_name_construction_input(        -- also the name in different language
                                make_codekeyl_bystr('rus')
                              , 'Тренеруемся на кошках 1234567890'
                              , make_codekeyl_null()
                              , 'описание...'
                              )
                      ] :: name_construction_input[]
              , ARRAY [ mk_person_language_construction_input(
                                  make_codekeyl_bystr('eng') -- language posessed by person
                                , 20                         -- skill    of use by person [-100..100]
                                , 20                         -- priority of use by person [-100..100]
                                )
                      , mk_person_language_construction_input( -- another language posessed by person
                                  make_codekeyl_bystr('rus')
                                , 60
                                , 60
                                )
                      ] :: t_person_language_construction_input[]
              )
     ;

\echo
\echo --------------------------------------------------------------
\echo

SELECT new_person(
                make_codekeyl_bystr('human') -- type of person
              , ARRAY [ mk_name_construction_input(
                                make_codekeyl_bystr('eng') -- language of name
                              , 'Secretary of Test person 1234567890'   -- name
                              , make_codekeyl_null()       -- entity (will be set automatically to default, which for persons is "person")
                              , 'description...'           -- description
                              )
                      , mk_name_construction_input(        -- also the name in different language
                                make_codekeyl_bystr('rus')
                              , 'Секретариат по делам тренеровок на кошках 1234567890'
                              , make_codekeyl_null()
                              , 'описание...'
                              )
                      ] :: name_construction_input[]
              , ARRAY [ mk_person_language_construction_input(
                                  make_codekeyl_bystr('eng') -- language posessed by person
                                , 20                         -- skill    of use by person [-100..100]
                                , 20                         -- priority of use by person [-100..100]
                                )
                      , mk_person_language_construction_input( -- another language posessed by person
                                  make_codekeyl_bystr('rus')
                                , 60
                                , 60
                                )
                      ] :: t_person_language_construction_input[]
              )
     ;

\echo
\echo --------------------------------------------------------------
\echo

SELECT instaniate_contact_as_email(
                new_abstract_contact(
                        p.person_id
                      , mk_contact_construction_input(
                                 make_codekeyl_bystr('e-mail')
                               , 0
                               , 'constraints...'
                               )
                      , ARRAY [ mk_name_construction_input(
                                        make_codekeyl_bystr('eng')
                                      , 'Secretary of Test person 1234567890 e-mail.'
                                      , make_codekeyl_null()
                                      , 'Secretary of Test person 1234567890 e-mail description.'
                                      )
                              , mk_name_construction_input(
                                        make_codekeyl_bystr('rus')
                                      , 'Э-почта Секретариата по делам тренеровок на кошках 1234567890'
                                      , make_codekeyl_null()
                                      , 'Описание э-почты Секретариата по делам тренеровок на кошках 1234567890.'
                                      )
                              ]
                      )
              , ROW('nick2@mailserver.zzz') :: contact_email_construction_input
              )
FROM find_persons_by_name(
                make_codekeyl_null()
              , '^Secretary of Test person 1234567890$'
              , '~'
              ) AS p;

\echo
\echo --------------------------------------------------------------
\echo

SELECT instaniate_contact_as_email(
                new_abstract_contact(
                        p.person_id
                      , mk_contact_construction_input(
                                 make_codekeyl_bystr('e-mail')
                               , 0
                               , 'constraints...'
                               )
                      , ARRAY [ mk_name_construction_input(
                                        make_codekeyl_bystr('eng')
                                      , 'Test person 1234567890 e-mail.'
                                      , make_codekeyl_null()
                                      , 'Test person 1234567890 e-mail description.'
                                      )
                              , mk_name_construction_input(
                                        make_codekeyl_bystr('rus')
                                      , 'Э-почта тестовой персоны'
                                      , make_codekeyl_null()
                                      , 'Описание э-почты тестовой персоны.'
                                      )
                              ]
                      )
              , ROW('nick@mailserver.zzz') :: contact_email_construction_input
              )
FROM find_persons_by_name(
                make_codekeyl_null()
              , '^Test person 1234567890$'
              , '~'
              ) AS p;

\echo
\echo --------------------------------------------------------------
\echo

SELECT instaniate_contact_as_phone(
                new_abstract_contact(
                        p.person_id
                      , mk_contact_construction_input(
                                 make_codekeyl_bystr('phone')
                               , 0
                               , 'constraints...'
                               )
                      , ARRAY [ mk_name_construction_input(
                                        make_codekeyl_bystr('eng')
                                      , 'Test person 1234567890 phone.'
                                      , make_codekeyl_null()
                                      , 'Test person 1234567890 phone description.'
                                      )
                              , mk_name_construction_input(
                                        make_codekeyl_bystr('rus')
                                      , 'Телефон тестовой персоны'
                                      , make_codekeyl_null()
                                      , 'Описание телефона тестовой персоны.'
                                      )
                              ]
                      )
              , ROW('1234567890') :: contact_phone_construction_input
              )
FROM find_persons_by_name(
                make_codekeyl_null()
              , '^Тренеруемся на кошках 1234567890$'
              , '~'
              ) AS p;

\echo
\echo --------------------------------------------------------------
\echo

SELECT instaniate_contact_as_fax(
                new_abstract_contact(
                        p.person_id
                      , mk_contact_construction_input(
                                 make_codekeyl_bystr('fax')
                               , 0
                               , 'constraints...'
                               )
                      , ARRAY [ mk_name_construction_input(
                                        make_codekeyl_bystr('eng')
                                      , 'Test person 1234567890 fax.'
                                      , make_codekeyl_null()
                                      , 'Test person 1234567890 fax description.'
                                      )
                              , mk_name_construction_input(
                                        make_codekeyl_bystr('rus')
                                      , 'Факс тестовой персоны'
                                      , make_codekeyl_null()
                                      , 'Описание факса тестовой персоны.'
                                      )
                              ]
                      )
              , ROW('1234567890z') :: contact_fax_construction_input
              )
FROM find_persons_by_name(
                make_codekeyl_bystr('rus')
              , '^Тренеруемся на кошках 1234567890$'
              , '~'
              ) AS p;

\echo
\echo --------------------------------------------------------------
\echo

SELECT instaniate_contact_as_postal(
                new_abstract_contact(
                        p.person_id
                      , mk_contact_construction_input(
                                 make_codekeyl_bystr('postal')
                               , 0
                               , 'constraints...'
                               )
                      , ARRAY [ mk_name_construction_input(
                                        make_codekeyl_bystr('eng')
                                      , 'Test person 1234567890 postal addr.'
                                      , make_codekeyl_null()
                                      , 'Test person 1234567890 postal addr description.'
                                      )
                              , mk_name_construction_input(
                                        make_codekeyl_bystr('rus')
                                      , 'Почтовый адрес тестовой персоны'
                                      , make_codekeyl_null()
                                      , 'Описание почтового адреса тестовой персоны.'
                                      )
                              ]
                      )
              , ROW( (ARRAY( SELECT person_id
                             FROM find_persons_by_name( -- this trick isn't usable in real system, because you can't uniquely identify person by it's name
                                     make_codekeyl_bystr('eng')
                                   , '^Secretary of Test person 1234567890$'
                                   , '~'
                                   )
                           )
                     )[1]
                   , new_postal_address( ROW ( make_codekeyl_bystr('eng')
                                             , 'Zimbabve'
                                             , 'wall street region'
                                             , 'Nonexitopolis'
                                             , 'asdfqwer1234'
                                             , 'owned by bush street'
                                       )     )
                   ) :: contact_postal_construction_input
              )
     , instaniate_contact_as_postal(
                new_abstract_contact(
                        p.person_id
                      , mk_contact_construction_input(
                                 make_codekeyl_bystr('postal')
                               , 0
                               , 'constraints... 2'
                               )
                      , ARRAY [ mk_name_construction_input(
                                        make_codekeyl_bystr('eng')
                                      , 'Test person 1234567890 postal addr. 2'
                                      , make_codekeyl_null()
                                      , 'Test person 1234567890 postal addr description. 2'
                                      )
                              , mk_name_construction_input(
                                        make_codekeyl_bystr('rus')
                                      , 'Почтовый адрес тестовой персоны 2'
                                      , make_codekeyl_null()
                                      , 'Описание почтового адреса тестовой персоны. 2'
                                      )
                              ]
                      )
              , ROW( NULL
                   , new_postal_address( ROW ( make_codekeyl_bystr('eng')
                                             , 'Zimbabve2'
                                             , 'wall street region2'
                                             , 'Nonexitopolis2'
                                             , 'asdfqwer1234 2'
                                             , 'owned by bush street 2'
                                       )     )
                   ) :: contact_postal_construction_input
              )
FROM find_persons_by_name(
                make_codekeyl_bystr('eng')
              , '^Test person 1234567890$'
              , '~'
              ) AS p;

\echo
\echo --------------------------------------------------------------
\echo

SELECT instaniate_contact_as_system_id(
                new_abstract_contact(
                        p.person_id
                      , mk_contact_construction_input(
                                 make_codekeyl_bystr('ID in some system')
                               , 0
                               , 'constraints...'
                               )
                      , ARRAY [ mk_name_construction_input(
                                        make_codekeyl_bystr('eng')
                                      , 'Test person 1234567890 ID in some system.'
                                      , make_codekeyl_null()
                                      , 'Test person 1234567890 ID in some system description.'
                                      )
                              , mk_name_construction_input(
                                        make_codekeyl_bystr('rus')
                                      , 'Ник тестовой персоны'
                                      , make_codekeyl_null()
                                      , 'Описание ника тестовой персоны.'
                                      )
                              ]
                      )
              , ROW( make_codekeyl_bystr('skype')
                   , 'my-funny-nick'
                   , ''
                   ) :: contact_system_id_construction_input
              )
FROM find_persons_by_name(
                make_codekeyl_bystr('rus')
              , '^Тренеруемся на кошках 1234567890$'
              , '~'
              ) AS p;

\echo
\echo --------------------------------------------------------------
\echo

SELECT instaniate_contact_as_person(
                new_abstract_contact(
                        p.person_id
                      , mk_contact_construction_input(
                                 make_codekeyl_bystr('another person')
                               , 0
                               , 'constraints...'
                               )
                      , ARRAY [ mk_name_construction_input(
                                        make_codekeyl_bystr('eng')
                                      , 'Test person 1234567890 ID represented by another person.'
                                      , make_codekeyl_null()
                                      , 'Test person 1234567890 ID represented by another person description.'
                                      )
                              , mk_name_construction_input(
                                        make_codekeyl_bystr('rus')
                                      , 'Представитель тестовой персоны'
                                      , make_codekeyl_null()
                                      , 'Описание представителя тестовой персоны.'
                                      )
                              ]
                      )
              , ROW(   (ARRAY( SELECT person_id
                               FROM find_persons_by_name(
                                      make_codekeyl_bystr('eng')
                                    , '^Secretary of Test person 1234567890$'
                                    , '~'
                                    )
                       )     )[1]
                   ,  'Secretary is empowered sign X and Y documents for Test person 1234567890, '
                   || 'and also receives its email. But won''t answerdirect phone calls - for this refer to Secretary2'
                   ) :: contact_person_construction_input
              )
FROM find_persons_by_name(
                make_codekeyl_bystr('rus')
              , '^Тренеруемся на кошках 1234567890$'
              , '~'
              ) AS p;

\echo
\echo --------------------------------------------------------------
\echo

SELECT * FROM find_contacts_of_person(
                       (ARRAY( SELECT person_id
                               FROM find_persons_by_name( -- this trick isn't usable in real system, because you can't uniquely identify person by it's name
                                      make_codekeyl_bystr('eng')
                                    , '^Test person 1234567890$'
                                    , '~'
                                    )
                       )     )[1]
              );

SELECT * FROM persons;
SELECT * FROM contacts;

\echo
\echo --------------------------------------------------------------
\echo

\echo ===========>>>>>>>>>> Testing triggers' constraints.

\echo >>>>>>>>>> This should raise error.
INSERT INTO contacts (contact_id, person_id, contact_type, contact_instaniated_isit) VALUES (77777, 1, NULL, TRUE);

\echo >>>>>>>>>> Correct operation.
INSERT INTO contacts (contact_id, person_id, contact_type, contact_instaniated_isit) VALUES (77777, 1, NULL, FALSE);

\echo >>>>>>>>>> This should raise error.
INSERT INTO contacts__phones (contact_id, phone_numb) VALUES (77777, 'adasdasdasdd');

\echo >>>>>>>>>> Correct operation.
UPDATE contacts SET contact_type = code_id_of( FALSE, make_acodekeyl_bystr2('Personal contacts types', 'phone')) WHERE contact_id = 77777;

\echo >>>>>>>>>> This should raise error.
UPDATE contacts SET contact_instaniated_isit = TRUE WHERE contact_id = 77777;

\echo >>>>>>>>>> Correct operation.
INSERT INTO contacts__phones (contact_id, phone_numb) VALUES (77777, 'adasdasdasdd');

\echo >>>>>>>>>> contact_instaniated_isit should be FALSE.
SELECT * FROM contacts WHERE contact_id = 77777;

\echo >>>>>>>>>> Correct operation.
UPDATE contacts SET contact_instaniated_isit = TRUE WHERE contact_id = 77777;

\echo >>>>>>>>>> This should raise error.
UPDATE contacts SET contact_type = code_id_of( FALSE, make_acodekeyl_bystr2('Personal contacts types', 'fax')) WHERE contact_id = 77777;

\echo >>>>>>>>>> This should raise error.
INSERT INTO contacts__faxes (contact_id, fax_numb) VALUES (77777, 'adasdasdasdd');

\echo >>>>>>>>>> Correct operation.
UPDATE contacts SET contact_instaniated_isit = FALSE WHERE contact_id = 77777;

\echo >>>>>>>>>> This should raise error.
UPDATE contacts SET contact_type = code_id_of( FALSE, make_acodekeyl_bystr2('Personal contacts types', 'fax')) WHERE contact_id = 77777;

\echo >>>>>>>>>> This should raise error.
INSERT INTO contacts__faxes (contact_id, fax_numb) VALUES (77777, 'adasdasdasdd');

\echo >>>>>>>>>> Correct operation.
UPDATE contacts SET contact_instaniated_isit = TRUE WHERE contact_id = 77777;

\echo >>>>>>>>>> Correct operation.
DELETE FROM contacts__phones WHERE contact_id = 77777;

\echo >>>>>>>>>> contact_instaniated_isit should be FALSE.
SELECT * FROM contacts WHERE contact_id = 77777;

\echo >>>>>>>>>> Correct operation.
UPDATE contacts SET contact_type = code_id_of( FALSE, make_acodekeyl_bystr2('Personal contacts types', 'fax')) WHERE contact_id = 77777;

\echo >>>>>>>>>> This should raise error.
INSERT INTO contacts__phones (contact_id, phone_numb) VALUES (77777, 'adasdasdasdd');

\echo >>>>>>>>>> Correct operation.
INSERT INTO contacts__faxes (contact_id, fax_numb) VALUES (77777, 'adasdasdasdd');

\echo >>>>>>>>>> Correct operation.
UPDATE contacts SET contact_instaniated_isit = TRUE WHERE contact_id = 77777;

\echo >>>>>>>>>> Correct operation.
INSERT INTO contacts (contact_id, person_id, contact_type, contact_instaniated_isit) VALUES (77778, 1, NULL, FALSE);

\echo >>>>>>>>>> This should raise error.
UPDATE contacts__faxes SET contact_id = 77778 WHERE contact_id = 77777;

\echo >>>>>>>>>> Correct operation.
UPDATE contacts SET contact_type = code_id_of( FALSE, make_acodekeyl_bystr2('Personal contacts types', 'fax')) WHERE contact_id = 77778;

\echo >>>>>>>>>> Correct operation.
UPDATE contacts__faxes SET contact_id = 77778 WHERE contact_id = 77777;

\echo >>>>>>>>>> contact_instaniated_isit should be FALSE.
SELECT * FROM contacts WHERE contact_id = 77777;

DELETE FROM contacts WHERE contact_id = 77778 OR contact_id = 77777;

\echo
\echo --------------------------------------------------------------
\echo

\echo ===========>>>>>>>>>> Testing FK restrictions.
SELECT p.person_id
FROM find_persons_by_name(
          make_codekeyl_bystr('eng')
        , '^Secretary of Test person 1234567890$'
        , '~'
        ) AS p;
SELECT * FROM contacts__emails;

\echo >>>>>>>>>> This should raise error.
DELETE FROM persons
WHERE person_id IN
        ( SELECT p.person_id
          FROM find_persons_by_name(
                 make_codekeyl_bystr('eng')
               , '^Secretary of Test person 1234567890$'
               , '~'
               ) AS p
        );

SELECT * FROM contacts__emails;

\echo >>>>>>>>>> One less obstacle to delete secretary
DELETE FROM contacts WHERE contact_id IN (SELECT cn.contact_id FROM contacts_names AS cn WHERE cn.name = 'Test person 1234567890 ID represented by another person.');

\echo >>>>>>>>>> Still this should raise error.
DELETE FROM persons
WHERE person_id IN
        ( SELECT p.person_id
          FROM find_persons_by_name(
                make_codekeyl_bystr('eng')
              , '^Secretary of Test person 1234567890$'
              , '~'
              ) AS p
        );

SELECT * FROM contacts__emails;

\echo >>>>>>>>>> Remove last obstacle to delete secretary
DELETE FROM contacts WHERE contact_id IN (SELECT cn.contact_id FROM contacts_names AS cn WHERE cn.name = 'Test person 1234567890 postal addr.');

\echo >>>>>>>>>> But recover old obstacle to delete secretary
SELECT instaniate_contact_as_person(
                new_abstract_contact(
                        p.person_id
                      , mk_contact_construction_input(
                                 make_codekeyl_bystr('another person')
                               , 0
                               , 'constraints...'
                               )
                      , ARRAY [ mk_name_construction_input(
                                        make_codekeyl_bystr('eng')
                                      , 'Test person 1234567890 ID represented by another person.'
                                      , make_codekeyl_null()
                                      , 'Test person 1234567890 ID represented by another person description.'
                                      )
                              , mk_name_construction_input(
                                        make_codekeyl_bystr('rus')
                                      , 'Представитель тестовой персоны'
                                      , make_codekeyl_null()
                                      , 'Описание представителя тестовой персоны.'
                                      )
                              ]
                      )
              , ROW(   (ARRAY( SELECT person_id
                               FROM find_persons_by_name(
                                      make_codekeyl_bystr('eng')
                                    , '^Secretary of Test person 1234567890$'
                                    , '~'
                                    )
                       )     )[1]
                   ,  'Secretary is empowered sign X and Y documents for Test person 1234567890, '
                   || 'and also receives its email. But won''t answerdirect phone calls - for this refer to Secretary2'
                   ) :: contact_person_construction_input
              )
FROM find_persons_by_name(
                make_codekeyl_bystr('rus')
              , '^Тренеруемся на кошках 1234567890$'
              , '~'
              ) AS p;

\echo >>>>>>>>>> Still this should raise error.
DELETE FROM persons
WHERE person_id IN
        ( SELECT p.person_id
          FROM find_persons_by_name(
                make_codekeyl_bystr('eng')
              , '^Secretary of Test person 1234567890$'
              , '~'
              ) AS p
        );

SELECT * FROM contacts__emails;

\echo >>>>>>>>>> Remove last obstacle to delete secretary
DELETE FROM contacts WHERE contact_id IN (SELECT cn.contact_id FROM contacts_names AS cn WHERE cn.name = 'Test person 1234567890 ID represented by another person.');

\echo >>>>>>>>>> Finally, remove secretary!
DELETE FROM persons
WHERE person_id IN
        ( SELECT p.person_id
          FROM find_persons_by_name(
                make_codekeyl_bystr('eng')
              , '^Secretary of Test person 1234567890$'
              , '~'
              ) AS p
        );

SELECT * FROM contacts__emails;

DELETE FROM persons
WHERE person_id IN
        ( SELECT p.person_id
          FROM find_persons_by_name(
                make_codekeyl_bystr('rus')
              , '^Тренеруемся на кошках 1234567890$'
              , '~'
              ) AS p
        );

\echo >>>>>>>>>> Test case removed. Testing finishaed.

\echo
\echo --------------------------------------------------------------
\echo

SELECT * FROM persons;
SELECT * FROM contacts;

\c <<$db_name$>> user_<<$app_name$>>_owner

SET search_path TO sch_<<$app_name$>>, public;
\set ECHO queries

ALTER SEQUENCE  persons_ids_seq RESTART WITH 100;
ALTER SEQUENCE contacts_ids_seq RESTART WITH 100;
