-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> contacts_instances/c_person.init.sql [BEGIN]

--------------------------------------------------------------------------
--------------------------------------------------------------------------

SELECT add_subcodes_under_codifier(
                make_codekeyl_bystr('Personal contacts types')
              , ''
              , VARIADIC ARRAY [ ROW('another person', 'plain code') ] :: code_construction_input[]
              );

UPDATE codes SET additional_field_1 = 'contacts__persons' WHERE code_id = code_id_of(FALSE, make_acodekeyl_bystr2('Personal contacts types', 'another person'));

------------

CREATE TABLE contacts__persons (
         contact_id  integer NOT NULL REFERENCES contacts (contact_id) ON DELETE CASCADE  ON UPDATE CASCADE
       , person_id   integer NOT NULL REFERENCES persons   (person_id) ON DELETE RESTRICT ON UPDATE CASCADE
       , representative_role_description
                     varchar     NULL
       , PRIMARY KEY (contact_id)
) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE contacts__persons TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT SELECT                         ON TABLE contacts__persons TO user_db<<$db_name$>>_app<<$app_name$>>_data_reader;

------------

CREATE INDEX representative_persons_of_contacts_idx ON contacts__persons(person_id) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>_idxs;

------------

CREATE TRIGGER tri_personal_contacts_onmodify AFTER INSERT OR UPDATE ON sch_<<$app_name$>>.contacts__persons
    FOR EACH ROW EXECUTE PROCEDURE personal_contact_detail_onmodify();

CREATE TRIGGER tri_personal_contacts_onderef AFTER DELETE OR UPDATE ON sch_<<$app_name$>>.contacts__persons
    FOR EACH ROW EXECUTE PROCEDURE personal_contact_detail_onderef();

------------------------------------------------
------------------------------------------------
------------------------------------------------
-- API:

CREATE TYPE contact_person_construction_input AS (
        person_id                       integer
      , representative_role_description varchar
);

CREATE OR REPLACE FUNCTION instaniate_contact_as_person(par_contact_id integer, par_contact_person_ci contact_person_construction_input) RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
        cnt integer:= 0;
BEGIN
        INSERT INTO sch_<<$app_name$>>.contacts__persons (
                                contact_id
                              , person_id
                              , representative_role_description
                              )
                       VALUES ( par_contact_id
                              , par_contact_person_ci.person_id
                              , par_contact_person_ci.representative_role_description
                              );
        GET DIAGNOSTICS cnt = ROW_COUNT;

        RETURN cnt;
END;
$$;

COMMENT ON FUNCTION instaniate_contact_as_person(par_contact_id integer, par_contact_person_ci contact_person_construction_input) IS
'Returns count of rows inserted (usually 1).
Before instaniating contact as an email, it must be of apropriate type - value of the "contacts.contact_type" field must be "another person" code. Orelse, an error will be triggered.
';

GRANT EXECUTE ON FUNCTION instaniate_contact_as_person(par_contact_id integer, par_contact_person_ci contact_person_construction_input)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> contacts_instances/c_person.init.sql [END]