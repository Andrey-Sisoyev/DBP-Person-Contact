-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>>> tests.prepare.sql [BEGIN]
\echo NOTICE >>>>>> Create table where testcases will be kept and functions to insert and cleanup test cases.
\echo

---------------------------
---------------------------

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

\echo NOTICE >>>>>> tests.prepare.sql [END]