-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\c <<$db_name$>> user_<<$app_name$>>_owner

SET search_path TO sch_<<$app_name$>>, public; -- sets only for current session

INSERT INTO dbp_packages (package_name, package_version, dbp_standard_version)
                   VALUES('<<$pkg.name$>>', '<<$pkg.ver$>>', '<<$pkg.std_ver$>>');

-- ^^^ don't change this !!

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

CREATE SEQUENCE persons_ids_seq
        INCREMENT BY 1
        MINVALUE 1
        START WITH 100
        NO CYCLE;

CREATE SEQUENCE contacts_ids_seq
        INCREMENT BY 1
        MINVALUE 1
        START WITH 100
        NO CYCLE;

GRANT USAGE ON SEQUENCE contacts_ids_seq TO user_<<$app_name$>>_data_admin;
GRANT USAGE ON SEQUENCE persons_ids_seq  TO user_<<$app_name$>>_data_admin;

-------------------------------------------------------------------------------

SELECT new_codifier_w_subcodes(
          make_codekeyl_bystr('Usual codifiers')
        , ROW ('Persons types', 'codifier' :: code_type) :: code_construction_input
        , ''
        , VARIADIC ARRAY[ ROW ( 'human', 'plain code' )
                        , ROW ( 'organization', 'plain code' )
                        ] :: code_construction_input[] -- subcodes
        );
SELECT bind_code_to_codifier(
                make_acodekeyl_bystr2('Common nominal codes set', 'undefined')
              , make_codekeyl_bystr('Persons types')
              , TRUE
              )
     , bind_code_to_codifier(
                make_acodekeyl_bystr2('Common nominal codes set', 'unclassified')
              , make_codekeyl_bystr('Persons types')
              , FALSE
              );

------

CREATE TABLE persons (
         person_id   integer NOT NULL DEFAULT nextval('sch_<<$app_name$>>.persons_ids_seq') PRIMARY KEY
       , person_type integer NOT NULL
       , CHECK (code_belongs_to_codifier(
                          FALSE
                        , make_acodekeyl( make_codekey_null()
                                        , make_codekey_bystr('Persons types')
                                        , make_codekey_byid(person_type)
               )        )               )
       , FOREIGN KEY (person_type) REFERENCES codes(code_id) ON DELETE RESTRICT ON UPDATE CASCADE
) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE persons  TO user_<<$app_name$>>_data_admin;
GRANT SELECT                         ON TABLE persons  TO user_<<$app_name$>>_data_reader;

-------------------------------------------------------------------------------

CREATE TABLE persons_languages (
         person_id             integer NOT NULL
       , lng_code              integer NOT NULL
       , lng_skill             integer     NULL           CHECK ((lng_skill >= -100 AND lng_skill <= 100) OR lng_skill IS NULL)
       , lng_personal_priority integer NOT NULL DEFAULT 0 CHECK  (lng_personal_priority >= -100 AND lng_personal_priority <= 100)
       , CHECK (code_belongs_to_codifier(
                          FALSE
                        , make_acodekeyl( make_codekey_null()
                                        , make_codekey_bystr('Languages')
                                        , make_codekey_byid(lng_code)
               )        )               )
       , FOREIGN KEY (person_id) REFERENCES persons (person_id) ON DELETE CASCADE  ON UPDATE CASCADE
       , FOREIGN KEY (lng_code)  REFERENCES codes(code_id)      ON DELETE RESTRICT ON UPDATE CASCADE
       , PRIMARY KEY (person_id, lng_code)
) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

COMMENT ON TABLE persons_languages IS '
Priority of use (field "lng_personal_priority"), the bigger, the more preferable by this person.
Field "lng_skill" is constrainted by values range [-100..100], the same is for field "lng_personal_priority".
';

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE persons_languages TO user_<<$app_name$>>_data_admin;
GRANT SELECT                         ON TABLE persons_languages TO user_<<$app_name$>>_data_reader;

-------------------------------------------------------------------------------

CREATE TABLE persons_names (
        person_id integer NOT NULL
      , PRIMARY KEY (person_id, lng_of_name)
      , FOREIGN KEY (person_id)  REFERENCES persons(person_id)
                                                            ON DELETE CASCADE  ON UPDATE CASCADE
      , FOREIGN KEY (lng_of_name) REFERENCES codes(code_id) ON DELETE RESTRICT ON UPDATE CASCADE
      , FOREIGN KEY (entity)      REFERENCES codes(code_id) ON DELETE RESTRICT ON UPDATE CASCADE
) INHERITS (named_in_languages)
  TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

SELECT new_code_by_userseqs(
                  ROW ('person', 'plain code' :: code_type) :: code_construction_input
                , make_codekeyl_bystr('Named entities')
                , FALSE
                , ''
                , 'sch_<<$app_name$>>.namentities_ids_seq'
                ) AS person_entity_id;

ALTER TABLE persons_names ALTER COLUMN entity SET DEFAULT code_id_of_entity('person');

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE persons_names TO user_<<$app_name$>>_data_admin;
GRANT SELECT                         ON TABLE persons_names TO user_<<$app_name$>>_data_reader;

CREATE INDEX names_of_persons_idx ON persons_names(name) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>_idxs;

-------------------------------------------------------------------------------

-- this codifier is filled in script ./contact_instances/main.init.sql
SELECT new_codifier_w_subcodes(
          make_codekeyl_bystr('Usual codifiers')
        , ROW ('Personal contacts types', 'codifier' :: code_type) :: code_construction_input
        , ''
        , VARIADIC ARRAY[ ] :: code_construction_input[] -- subcodes
        );
SELECT bind_code_to_codifier(
                make_acodekeyl_bystr2('Common nominal codes set', 'undefined')
              , make_codekeyl_bystr('Personal contacts types')
              , TRUE
              )
     , bind_code_to_codifier(
                make_acodekeyl_bystr2('Common nominal codes set', 'unclassified')
              , make_codekeyl_bystr('Personal contacts types')
              , FALSE
              );

------

CREATE TABLE contacts (
         contact_id   integer NOT NULL DEFAULT nextval('sch_<<$app_name$>>.contacts_ids_seq')
       , person_id    integer NOT NULL REFERENCES persons  (person_id)  ON DELETE CASCADE ON UPDATE CASCADE
       , contact_type integer     NULL
       , contact_instaniated_isit
                      boolean NOT NULL DEFAULT FALSE
       , contact_personal_priority
                      integer     NULL
       , contact_constraints
                      varchar     NULL
       , CHECK ((contact_type IS NULL AND NOT contact_instaniated_isit) OR contact_type IS NOT NULL)
       , CHECK (code_belongs_to_codifier(
                          FALSE
                        , make_acodekeyl( make_codekey_null()
                                        , make_codekey_bystr('Personal contacts types')
                                        , make_codekey_byid(contact_type)
               )        )               )
       , FOREIGN KEY (contact_type) REFERENCES codes(code_id) ON DELETE RESTRICT ON UPDATE CASCADE
       , PRIMARY KEY (contact_id)
) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE contacts TO user_<<$app_name$>>_data_admin;
GRANT SELECT                         ON TABLE contacts TO user_<<$app_name$>>_data_reader;

COMMENT ON TABLE contacts IS
'Some triggers are controlling complex relation between this table and tables cotaining contact details.
First of all, "contact_instaniated_isit" field value may be TRUE only when there is a corresponding entry in a contact detail table, which (table) is determined by value of "contact_type" field, and entry there is uniquely identified by "contact_id" FK.
If contact instaniation is deleted (or updated to refer different contact ID), then "contact_instaniated_isit" field automatically is set to FALSE.
Second, one can''t change value of "contact_type" field, if there is an instaniation of old type (in a table with contact details).
If an entry is deleted from table "contacts", then it''s instaniation in contact detail table is also deleted (this is controlled by ON DELETE CASCADE rule of foreign key).
';

CREATE INDEX persons_of_contacts_idx ON contacts(person_id) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>_idxs;
CREATE INDEX types_of_contacts_idx ON contacts(contact_type) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>_idxs;

-------------------------------------------------------------------------------

CREATE TABLE contacts_names (
        contact_id integer NOT NULL
      , PRIMARY KEY (contact_id, lng_of_name)
      , FOREIGN KEY (contact_id)  REFERENCES contacts(contact_id)
                                                            ON DELETE CASCADE  ON UPDATE CASCADE
      , FOREIGN KEY (lng_of_name) REFERENCES codes(code_id) ON DELETE RESTRICT ON UPDATE CASCADE
      , FOREIGN KEY (entity)      REFERENCES codes(code_id) ON DELETE RESTRICT ON UPDATE CASCADE
) INHERITS (named_in_languages)
  TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

SELECT new_code_by_userseqs(
                  ROW ('contact', 'plain code' :: code_type) :: code_construction_input
                , make_codekeyl_bystr('Named entities')
                , FALSE
                , ''
                , 'sch_<<$app_name$>>.namentities_ids_seq'
                ) AS contact_entity_id;

ALTER TABLE contacts_names ALTER COLUMN entity SET DEFAULT code_id_of_entity('contact');

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE contacts_names TO user_<<$app_name$>>_data_admin;
GRANT SELECT                         ON TABLE contacts_names TO user_<<$app_name$>>_data_reader;

CREATE INDEX names_of_contacts_idx ON contacts_names(name) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>_idxs;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Triggers:

CREATE OR REPLACE FUNCTION person_ondelete() RETURNS trigger AS $personal_contacts_onmodify$ -- before delete
BEGIN
        DELETE FROM sch_<<$app_name$>>.contacts WHERE person_id = OLD.person_id;
        RETURN OLD;
END;
$personal_contacts_onmodify$ LANGUAGE plpgsql;

CREATE TRIGGER tri_person_ondelete BEFORE DELETE ON sch_<<$app_name$>>.persons
    FOR EACH ROW EXECUTE PROCEDURE person_ondelete();

------------------

CREATE OR REPLACE FUNCTION personal_contacts_onmodify() RETURNS trigger AS $personal_contacts_onmodify$ -- upd, ins
DECLARE
        co sch_<<$app_name$>>.codes%ROWTYPE;
        tn regtype;
        exst boolean;
        cnt integer;
BEGIN
        IF TG_OP = 'UPDATE' THEN
                IF NEW.contact_type IS DISTINCT FROM OLD.contact_type AND OLD.contact_type IS NOT NULL THEN
                        co:= get_code(FALSE, make_acodekeyl_byid(OLD.contact_type));
                        tn:= co.additional_field_1;
                        EXECUTE 'SELECT TRUE FROM ' || tn || ' WHERE contact_id = $1' INTO exst USING NEW.contact_id;
                        GET DIAGNOSTICS cnt = ROW_COUNT;
                        IF cnt != 0 THEN
                                RAISE EXCEPTION 'An error occurred, when an % operation attempted on a contact with ID "%" in the table "sch_<<$app_name$>>.contacts"! Can''t change contact type, unless instance of old type is deleted (first you must delete row from "%" table by contact_id = "%").', TG_OP, OLD.contact_id, tn, OLD.contact_id;
                        END IF;
                END IF;
        END IF;

        IF NEW.contact_instaniated_isit THEN
                co:= get_code(FALSE, make_acodekeyl_byid(NEW.contact_type));
                tn:= co.additional_field_1;
                EXECUTE 'SELECT TRUE FROM ' || tn || ' WHERE contact_id = $1' INTO exst USING NEW.contact_id;
                GET DIAGNOSTICS cnt = ROW_COUNT;
                IF cnt != 1 THEN
                        IF cnt > 0 THEN
                                RAISE EXCEPTION 'An error occurred, when an % operation attempted on a contact with ID "%" in the table "sch_<<$app_name$>>.contacts"! There seems to be multiple contact entries in a table referred by the "contact_type" field, which is not allowed.', TG_OP, NEW.contact_id;
                        ELSIF cnt = 0 THEN
                                RAISE EXCEPTION 'An error occurred, when an % operation attempted on a contact with ID "%" in the table "sch_<<$app_name$>>.contacts"! Field "contact_instaniated_isit" may be set to TRUE only in case, when there is a contact entry in a table referred by the "contact_type" field.', TG_OP, NEW.contact_id;
                        END IF;
                END IF;
        END IF;

        RETURN NEW;
END;
$personal_contacts_onmodify$ LANGUAGE plpgsql;

CREATE TRIGGER tri_personal_contacts_onmodify AFTER INSERT OR UPDATE ON sch_<<$app_name$>>.contacts
    FOR EACH ROW EXECUTE PROCEDURE personal_contacts_onmodify();

------------------

CREATE OR REPLACE FUNCTION personal_contact_detail_onmodify() RETURNS trigger AS $personal_contact_detail_onmodify$ -- upd, ins
DECLARE
        cont sch_<<$app_name$>>.contacts%ROWTYPE;
        code sch_<<$app_name$>>.codes%ROWTYPE;
        tn regtype;
        exst boolean;
        cnt integer;
BEGIN
        SELECT * INTO cont FROM sch_<<$app_name$>>.contacts WHERE contact_id = NEW.contact_id;
        IF cont.contact_type IS NULL THEN
                RAISE EXCEPTION 'An error occurred, when an % operation attempted on a contact detail table "%" with contact ID "%". Contact type (field "contacts.contact_type") is not specified - cannot work with contact details, when contact type is unknown.', TG_OP, TG_TABLE_NAME, NEW.contact_id;
        END IF;

        code:= sch_<<$app_name$>>.get_code(FALSE, make_acodekeyl_byid(cont.contact_type));
        tn:= code.additional_field_1;

        IF (TG_TABLE_NAME :: regtype) IS DISTINCT FROM tn THEN
                RAISE EXCEPTION 'An error occurred, when an % operation attempted on a contact detail table "%" with contact ID "%". The contact is of different type (according to "contacts.contact_type" field), it''s details are to be stored in different contact-detail table - in "%".', TG_OP, TG_TABLE_NAME, NEW.contact_id, tn;
        END IF;

        RETURN NEW;
END;
$personal_contact_detail_onmodify$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION personal_contact_detail_onderef() RETURNS trigger AS $personal_contact_detail_onderef$ -- upd, del
BEGIN
        IF    TG_OP = 'DELETE' THEN
                UPDATE sch_<<$app_name$>>.contacts SET contact_instaniated_isit = FALSE WHERE contact_id = OLD.contact_id;
                RETURN NULL;
        ELSIF TG_OP = 'UPDATE' THEN
                IF NEW.contact_id IS DISTINCT FROM OLD.contact_id THEN
                        UPDATE sch_<<$app_name$>>.contacts SET contact_instaniated_isit = FALSE WHERE contact_id = OLD.contact_id;
                END IF;
                RETURN NEW;
        END IF;
END;
$personal_contact_detail_onderef$ LANGUAGE plpgsql;

-- CREATE ...
-- GRANT ...

-- Sometimes we want to insert some data, before creating triggers.
\i functions.init.sql
\i ../data/data.sql

-- CREATE TRIGGER ...