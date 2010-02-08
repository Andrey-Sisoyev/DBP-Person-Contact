-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo c_phone.init.sql

SELECT add_subcodes_under_codifier(
                make_codekeyl_bystr('Personal contacts types')
              , ''
              , VARIADIC ARRAY [ ROW('phone', 'plain code') ] :: code_construction_input[]
              );

UPDATE codes SET additional_field_1 = 'contacts__phones' WHERE code_id = code_id_of(FALSE, make_acodekeyl_bystr2('Personal contacts types', 'phone'));

------------

CREATE TABLE contacts__phones (
         contact_id  integer NOT NULL REFERENCES contacts (contact_id) ON DELETE CASCADE ON UPDATE CASCADE
       , phone_numb  varchar NOT NULL
       , PRIMARY KEY (contact_id)
) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE contacts__phones TO user_<<$app_name$>>_data_admin;
GRANT SELECT                         ON TABLE contacts__phones TO user_<<$app_name$>>_data_reader;

------------

CREATE INDEX phones_of_contacts_idx ON contacts__phones(phone_numb) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>_idxs;

------------

CREATE TRIGGER tri_personal_contacts_onmodify AFTER INSERT OR UPDATE ON sch_<<$app_name$>>.contacts__phones
    FOR EACH ROW EXECUTE PROCEDURE personal_contact_detail_onmodify();

CREATE TRIGGER tri_personal_contacts_onderef AFTER DELETE OR UPDATE ON sch_<<$app_name$>>.contacts__phones
    FOR EACH ROW EXECUTE PROCEDURE personal_contact_detail_onderef();

------------------------------------------------
------------------------------------------------
------------------------------------------------
-- API:

CREATE TYPE contact_phone_construction_input AS (
        phone_numb varchar
);

CREATE OR REPLACE FUNCTION instaniate_contact_as_phone(par_contact_id integer, par_contact_phone_ci contact_phone_construction_input) RETURNS integer AS $$
DECLARE
        cnt integer:= 0;
BEGIN
        INSERT INTO sch_<<$app_name$>>.contacts__phones (
                                contact_id
                              , phone_numb
                              )
                       VALUES ( par_contact_id
                              , par_contact_phone_ci.phone_numb
                              );

        GET DIAGNOSTICS cnt = ROW_COUNT;

        RETURN cnt;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION instaniate_contact_as_phone(par_contact_id integer, par_contact_phone_ci contact_phone_construction_input) IS
'Returns count of rows inserted (usually 1).
Before instaniating contact as an email, it must be of apropriate type - value of the "contacts.contact_type" field must be "phone" code. Orelse, an error will be triggered.
';

GRANT EXECUTE ON FUNCTION instaniate_contact_as_phone(par_contact_id integer, par_contact_phone_ci contact_phone_construction_input)TO user_<<$app_name$>>_data_admin;
