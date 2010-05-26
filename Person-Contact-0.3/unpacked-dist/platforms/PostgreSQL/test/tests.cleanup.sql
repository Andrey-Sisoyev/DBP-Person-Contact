-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>>> tests.cleanup.sql [BEGIN]

\c <<$db_name$>> user_db<<$db_name$>>_app<<$app_name$>>_owner

SET search_path TO sch_<<$app_name$>>, public;
\set ECHO queries

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

DELETE FROM contacts WHERE contact_id IN (77777, 77778);

ALTER SEQUENCE  persons_ids_seq RESTART WITH 100;
ALTER SEQUENCE contacts_ids_seq RESTART WITH 100;

\echo NOTICE >>>>>> tests.cleanup.sql [END]
