-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>>> tests.functions.sql [BEGIN]

SELECT * FROM find_contacts_of_person(
                       (ARRAY( SELECT person_id
                               FROM find_persons_by_name( -- this trick isn't usable in real system, because you can't uniquely identify person by it's name
                                      make_codekeyl_bystr('eng')
                                    , '^Test person 1234567890$'
                                    , '~'
                                    )
                       )     )[1]
              );


\echo NOTICE >>>>>> tests.functions.sql [END]