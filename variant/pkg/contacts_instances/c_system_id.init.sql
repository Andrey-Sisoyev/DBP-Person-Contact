-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo c_system_id.init.sql

SELECT add_subcodes_under_codifier(
                make_codekeyl_bystr('Personal contacts types')
              , ''
              , VARIADIC ARRAY [ ROW('ID in some system', 'plain code') ] :: code_construction_input[]
              );

UPDATE codes SET additional_field_1 = 'contacts__systems_ids' WHERE code_id = code_id_of(FALSE, make_acodekeyl_bystr2('Personal contacts types', 'ID in some system'));

------------

SELECT new_codifier_w_subcodes(
          make_codekeyl_bystr('Usual codifiers')
        , ROW ('Persons registering systems', 'codifier' :: code_type) :: code_construction_input
        , ''
        , VARIADIC ARRAY[ ROW ( '<<$app_name$>>', 'plain code' )
                        , ROW ( 'skype', 'plain code' )
                        ] :: code_construction_input[] -- subcodes
        );
SELECT bind_code_to_codifier(
                make_acodekeyl_bystr2('Common nominal codes set', 'unclassified')
              , make_codekeyl_bystr('Persons registering systems')
              , TRUE
              );

------

CREATE TABLE contacts__systems_ids (
         contact_id  integer NOT NULL REFERENCES contacts (contact_id) ON DELETE CASCADE ON UPDATE CASCADE
       , system      integer NOT NULL
       , id_or_nick_in_system
                     varchar NOT NULL
       , additional_insystem_addr_info
                     varchar     NULL
       , CHECK (code_belongs_to_codifier(
                          FALSE
                        , make_acodekeyl( make_codekey_null()
                                        , make_codekey_bystr('Persons registering systems')
                                        , make_codekey_byid(system)
               )        )               )
       , FOREIGN KEY (system) REFERENCES codes(code_id) ON DELETE RESTRICT ON UPDATE CASCADE
       , PRIMARY KEY (contact_id)
) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE contacts__systems_ids TO user_<<$app_name$>>_data_admin;
GRANT SELECT                         ON TABLE contacts__systems_ids TO user_<<$app_name$>>_data_reader;

------------

CREATE INDEX nicks_of_contacts_idx ON contacts__systems_ids(system, id_or_nick_in_system) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>_idxs;
CREATE INDEX sysnicks_of_contacts_idx ON contacts__systems_ids(id_or_nick_in_system) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>_idxs;

------------

CREATE TRIGGER tri_personal_contacts_onmodify AFTER INSERT OR UPDATE ON sch_<<$app_name$>>.contacts__systems_ids
    FOR EACH ROW EXECUTE PROCEDURE personal_contact_detail_onmodify();

CREATE TRIGGER tri_personal_contacts_onderef AFTER DELETE OR UPDATE ON sch_<<$app_name$>>.contacts__systems_ids
    FOR EACH ROW EXECUTE PROCEDURE personal_contact_detail_onderef();

------------------------------------------------
------------------------------------------------
------------------------------------------------
-- API:

CREATE TYPE contact_system_id_construction_input AS (
        system                        t_code_key_by_lng
      , id_or_nick_in_system          varchar
      , additional_insystem_addr_info varchar
);

CREATE OR REPLACE FUNCTION instaniate_contact_as_system_id(par_contact_id integer, par_contact_system_id_ci contact_system_id_construction_input) RETURNS integer AS $$
DECLARE
        cnt integer:= 0;
BEGIN
        INSERT INTO sch_<<$app_name$>>.contacts__systems_ids (
                        contact_id
                      , system
                      , id_or_nick_in_system
                      , additional_insystem_addr_info
                      )
               VALUES ( par_contact_id
                      , code_id_of( FALSE, generalize_codekeyl_wcf(make_codekey_bystr('Persons registering systems'), par_contact_system_id_ci.system))
                      , par_contact_system_id_ci.id_or_nick_in_system
                      , par_contact_system_id_ci.additional_insystem_addr_info
                      );

        GET DIAGNOSTICS cnt = ROW_COUNT;

        RETURN cnt;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION instaniate_contact_as_system_id(par_contact_id integer, par_contact_system_id_ci contact_system_id_construction_input) IS
'Returns count of rows inserted (usually 1).
Before instaniating contact as an email, it must be of apropriate type - value of the "contacts.contact_type" field must be "ID in some system" code. Orelse, an error will be triggered.
';

GRANT EXECUTE ON FUNCTION instaniate_contact_as_system_id(par_contact_id integer, par_contact_system_id_ci contact_system_id_construction_input)TO user_<<$app_name$>>_data_admin;
