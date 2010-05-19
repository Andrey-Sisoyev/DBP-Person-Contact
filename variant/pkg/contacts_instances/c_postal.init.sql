-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> contacts_instances/c_postal.init.sql [BEGIN]

--------------------------------------------------------------------------
--------------------------------------------------------------------------

SELECT add_subcodes_under_codifier(
                make_codekeyl_bystr('Personal contacts types')
              , ''
              , VARIADIC ARRAY [ ROW('postal', 'plain code') ] :: code_construction_input[]
              );

UPDATE codes SET additional_field_1 = 'contacts__postal' WHERE code_id = code_id_of(FALSE, make_acodekeyl_bystr2('Personal contacts types', 'postal'));

-------------

CREATE SEQUENCE postal_addresses_ids_seq
        INCREMENT BY 1
        MINVALUE 1
        START WITH 100
        NO CYCLE;

GRANT USAGE ON SEQUENCE postal_addresses_ids_seq TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;

-------------

CREATE TABLE postal_addresses (
         postal_address_id integer NOT NULL DEFAULT nextval('sch_<<$app_name$>>.postal_addresses_ids_seq')
       , PRIMARY KEY (postal_address_id)
) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

CREATE TABLE contacts__postal (
         contact_id               integer NOT NULL REFERENCES contacts (contact_id) ON DELETE CASCADE  ON UPDATE CASCADE
       , mail_receiving_person_id integer NOT NULL REFERENCES persons   (person_id) ON DELETE RESTRICT ON UPDATE CASCADE
       , postal_address_id        integer NOT NULL REFERENCES postal_addresses (postal_address_id)
                                                                                    ON DELETE RESTRICT ON UPDATE CASCADE
       , PRIMARY KEY (contact_id)
) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

COMMENT ON TABLE contacts__postal IS
'Cases occur, when mail is addressed to one person in organization, but mail delivery is interfaced by another - receiving person.
Also, a letter may be addressed to organization, but the receiving person is human.
';


CREATE TABLE postal_addresses_in_languages (
         postal_address_id integer NOT NULL
       , lng_of_address    integer NOT NULL

       , country           varchar NOT NULL
       , region            varchar NOT NULL
       , city_or_town      varchar NOT NULL
       , postal_index      varchar NOT NULL
       , local_address     varchar NOT NULL

       , CHECK (code_belongs_to_codifier(
                          FALSE
                        , make_acodekeyl( make_codekey_null()
                                        , make_codekey_bystr('Languages')
                                        , make_codekey_byid(lng_of_address)
               )        )               )
       , FOREIGN KEY (postal_address_id) REFERENCES postal_addresses (postal_address_id)
                                                                   ON DELETE CASCADE  ON UPDATE CASCADE
       , FOREIGN KEY (lng_of_address)    REFERENCES codes(code_id) ON DELETE RESTRICT ON UPDATE CASCADE
       , PRIMARY KEY (postal_address_id, lng_of_address)
) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE contacts__postal              TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE postal_addresses_in_languages TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE postal_addresses              TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT SELECT                         ON TABLE contacts__postal              TO user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT SELECT                         ON TABLE postal_addresses_in_languages TO user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT SELECT                         ON TABLE postal_addresses              TO user_db<<$db_name$>>_app<<$app_name$>>_data_reader;

------------

CREATE TRIGGER tri_personal_contacts_onmodify AFTER INSERT OR UPDATE ON sch_<<$app_name$>>.contacts__postal
    FOR EACH ROW EXECUTE PROCEDURE personal_contact_detail_onmodify();

CREATE TRIGGER tri_personal_contacts_onderef AFTER DELETE OR UPDATE ON sch_<<$app_name$>>.contacts__postal
    FOR EACH ROW EXECUTE PROCEDURE personal_contact_detail_onderef();

------------------------------------------------
------------------------------------------------
------------------------------------------------
-- API:

CREATE TYPE postal_address_construction_input AS (
         lng_of_address t_code_key_by_lng
       , country        varchar
       , region         varchar
       , city_or_town   varchar
       , postal_index   varchar
       , local_address  varchar
);

CREATE OR REPLACE FUNCTION new_postal_address(par_postal_address_ci postal_address_construction_input) RETURNS integer
LANGUAGE plpgsql
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE
        pa_id integer:= NULL;
BEGIN
        INSERT INTO postal_addresses (postal_address_id) VALUES (DEFAULT)
        RETURNING postal_address_id INTO pa_id;

        INSERT INTO postal_addresses_in_languages (
                                postal_address_id
                              , lng_of_address
                              , country
                              , region
                              , city_or_town
                              , postal_index
                              , local_address
                              )
                       VALUES ( pa_id
                              , code_id_of( FALSE, generalize_codekeyl_wcf(make_codekey_bystr('Languages'), par_postal_address_ci.lng_of_address))
                              , par_postal_address_ci.country
                              , par_postal_address_ci.region
                              , par_postal_address_ci.city_or_town
                              , par_postal_address_ci.postal_index
                              , par_postal_address_ci.local_address
                              );

        RETURN pa_id;
END;
$$;

COMMENT ON FUNCTION new_postal_address(par_postal_address_ci postal_address_construction_input) IS
'Returns ID of newly created postal address.';

GRANT EXECUTE ON FUNCTION new_postal_address(par_postal_address_ci postal_address_construction_input)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;

-------------------------------------------------------------------

CREATE TYPE contact_postal_construction_input AS (
         mail_receiving_person_id integer
       , postal_address_id        integer
);

CREATE OR REPLACE FUNCTION instaniate_contact_as_postal(par_contact_id integer, par_contact_postal_ci contact_postal_construction_input) RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
        cnt integer:= 0;
        p_id integer;
BEGIN
        p_id:= COALESCE( par_contact_postal_ci.mail_receiving_person_id
                       , sch_<<$app_name$>>.find_person_by_contact(par_contact_id)
                       );

        INSERT INTO sch_<<$app_name$>>.contacts__postal (
                                contact_id
                              , postal_address_id
                              , mail_receiving_person_id
                              )
                       VALUES ( par_contact_id
                              , par_contact_postal_ci.postal_address_id
                              , p_id
                              );

        GET DIAGNOSTICS cnt = ROW_COUNT;

        RETURN cnt;
END;
$$;

COMMENT ON FUNCTION instaniate_contact_as_postal(par_contact_id integer, par_contact_postal_ci contact_postal_construction_input) IS
'Returns mail recepient person ID.
Before instaniating contact as an email, it must be of apropriate type - value of the "contacts.contact_type" field must be "postal" code. Orelse, an error will be triggered.
IF value of argument "par_contact_postal_ci.mail_receiving_person_id" is given NULL, then the ID of person that is reachable through this contact is inserted.
WARNING! you won''t be able to delete entry "persons", which has a postal contact referring to same person - you will have to delete
';

GRANT EXECUTE ON FUNCTION instaniate_contact_as_postal(par_contact_id integer, par_contact_postal_ci contact_postal_construction_input)TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> contacts_instances/c_postal.init.sql [END]
