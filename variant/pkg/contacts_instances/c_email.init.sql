-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo c_email.init.sql

SELECT add_subcodes_under_codifier(
                make_codekeyl_bystr('Personal contacts types')
              , ''
              , VARIADIC ARRAY [ ROW('e-mail', 'plain code') ] :: code_construction_input[]
              );

UPDATE codes SET additional_field_1 = 'contacts__emails' WHERE code_id = code_id_of(FALSE, make_acodekeyl_bystr2('Personal contacts types', 'e-mail'));

------------

CREATE TABLE contacts__emails (
         contact_id  integer NOT NULL REFERENCES contacts (contact_id) ON DELETE CASCADE ON UPDATE CASCADE
       , email       varchar NOT NULL
       , PRIMARY KEY (contact_id)
) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE contacts__emails TO user_<<$app_name$>>_data_admin;
GRANT SELECT                         ON TABLE contacts__emails TO user_<<$app_name$>>_data_reader;

------------

CREATE INDEX emails_of_contacts_idx ON contacts__emails(email) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>_idxs;

------------

CREATE TRIGGER tri_personal_contacts_onmodify AFTER INSERT OR UPDATE ON sch_<<$app_name$>>.contacts__emails
    FOR EACH ROW EXECUTE PROCEDURE personal_contact_detail_onmodify();

CREATE TRIGGER tri_personal_contacts_onderef AFTER DELETE OR UPDATE ON sch_<<$app_name$>>.contacts__emails
    FOR EACH ROW EXECUTE PROCEDURE personal_contact_detail_onderef();

------------------------------------------------
------------------------------------------------
------------------------------------------------
-- API:

CREATE TYPE contact_email_construction_input AS (
        email varchar
);

CREATE OR REPLACE FUNCTION instaniate_contact_as_email(par_contact_id integer, par_contact_email_ci contact_email_construction_input) RETURNS integer AS $$
DECLARE
        cnt integer:= 0;
BEGIN
        INSERT INTO sch_<<$app_name$>>.contacts__emails (
                                contact_id
                              , email
                              )
                       VALUES ( par_contact_id
                              , par_contact_email_ci.email
                              );
        GET DIAGNOSTICS cnt = ROW_COUNT;

        RETURN cnt;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION instaniate_contact_as_email(par_contact_id integer, par_contact_email_ci contact_email_construction_input) IS
'Returns count of rows inserted (usually 1).
Before instaniating contact as an email, it must be of apropriate type - value of the "contacts.contact_type" field must be "e-mail" code. Orelse, an error will be triggered.
';

GRANT EXECUTE ON FUNCTION instaniate_contact_as_email(par_contact_id integer, par_contact_email_ci contact_email_construction_input)TO user_<<$app_name$>>_data_admin;
