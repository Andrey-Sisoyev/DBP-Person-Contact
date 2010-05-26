-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> contacts_instances/c_fax.init.sql [BEGIN]

--------------------------------------------------------------------------
--------------------------------------------------------------------------

SELECT add_subcodes_under_codifier(
                make_codekeyl_bystr('Personal contacts types')
              , ''
              , VARIADIC ARRAY [ ROW('fax', 'plain code') ] :: code_construction_input[]
              );

UPDATE codes SET additional_field_1 = 'contacts__faxes' WHERE code_id = code_id_of(FALSE, make_acodekeyl_bystr2('Personal contacts types', 'fax'));

------------

CREATE TABLE contacts__faxes (
         contact_id  integer NOT NULL REFERENCES contacts (contact_id) ON DELETE CASCADE ON UPDATE CASCADE
       , fax_numb    varchar NOT NULL
       , PRIMARY KEY (contact_id)
) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE contacts__faxes TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT SELECT                         ON TABLE contacts__faxes TO user_db<<$db_name$>>_app<<$app_name$>>_data_reader;

------------

CREATE INDEX faxes_of_contacts_idx ON contacts__faxes(fax_numb) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>_idxs;

------------

CREATE TRIGGER tri_personal_contacts_onmodify AFTER INSERT OR UPDATE ON sch_<<$app_name$>>.contacts__faxes
    FOR EACH ROW EXECUTE PROCEDURE personal_contact_detail_onmodify();

CREATE TRIGGER tri_personal_contacts_onderef AFTER DELETE OR UPDATE ON sch_<<$app_name$>>.contacts__faxes
    FOR EACH ROW EXECUTE PROCEDURE personal_contact_detail_onderef();

------------------------------------------------
------------------------------------------------
------------------------------------------------
-- API:

CREATE TYPE contact_fax_construction_input AS (
        fax_numb varchar
);

CREATE OR REPLACE FUNCTION instaniate_contact_as_fax(par_contact_id integer, par_contact_fax_ci contact_fax_construction_input) RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
        cnt integer:= 0;
BEGIN
        INSERT INTO sch_<<$app_name$>>.contacts__faxes (
                                contact_id
                              , fax_numb
                              )
                       VALUES ( par_contact_id
                              , par_contact_fax_ci.fax_numb
                              );
        GET DIAGNOSTICS cnt = ROW_COUNT;

        RETURN cnt;
END;
$$;

COMMENT ON FUNCTION instaniate_contact_as_fax(par_contact_id integer, par_contact_fax_ci contact_fax_construction_input) IS
'Returns count of rows inserted (usually 1).
Before instaniating contact as an email, it must be of apropriate type - value of the "contacts.contact_type" field must be "fax" code. Orelse, an error will be triggered.
';

GRANT EXECUTE ON FUNCTION instaniate_contact_as_fax(par_contact_id integer, par_contact_fax_ci contact_fax_construction_input)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> contacts_instances/c_fax.init.sql [END]

