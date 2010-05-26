-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>>> tests.triggers.sql [BEGIN]

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

\echo >>>>>>>>>> Test case removed. Testing finishaed.

\echo NOTICE >>>>>> tests.triggers.sql [END]
