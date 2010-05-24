-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\c <<$db_name$>> user_db<<$db_name$>>_app<<$app_name$>>_owner

SET search_path TO sch_<<$app_name$>>, comn_funs, public; -- sets only for current session
\set ECHO none

INSERT INTO dbp_packages (package_name, package_version, dbp_standard_version)
                   VALUES('<<$pkg.name$>>', '<<$pkg.ver$>>', '<<$pkg.std_ver$>>');

-- ^^^ don't change this !!
--
-- IF CREATING NEW CUSTOM ROLES/TABLESPACES, then don't forget to register
-- them (under application owner DB account) using
-- FUNCTION public.register_cwobj_tobe_dependant_on_current_dbapp(
--        par_cwobj_name              varchar
--      , par_cwobj_type              t_clusterwide_obj_types
--      , par_cwobj_additional_data_1 varchar
--      , par_application_name        varchar
--      , par_drop_it_by_cascade_when_dropping_db  boolean
--      , par_drop_it_by_cascade_when_dropping_app boolean
--      )
-- , where TYPE public.t_clusterwide_obj_types IS ENUM ('tablespace', 'role')

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
\echo NOTICE >>>>> structure.init.sql [BEGIN]

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

GRANT USAGE ON SEQUENCE contacts_ids_seq TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT USAGE ON SEQUENCE persons_ids_seq  TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;

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

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE persons  TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT SELECT                         ON TABLE persons  TO user_db<<$db_name$>>_app<<$app_name$>>_data_reader;

-------------------------------------------------------------------------------

CREATE TABLE persons_languages (
         person_id             integer NOT NULL
       , lng_code              integer NOT NULL
       , lng_skill             integer     NULL           CHECK ((lng_skill >= -100 AND lng_skill <= 100) OR lng_skill IS NULL)
       , lng_personal_priority integer NOT NULL DEFAULT 0 CHECK  (lng_personal_priority >= -100 AND lng_personal_priority <= 100)
       , FOREIGN KEY (lng_code)  REFERENCES languages(code_id)  ON UPDATE CASCADE ON DELETE RESTRICT
       , FOREIGN KEY (person_id) REFERENCES persons (person_id) ON DELETE CASCADE ON UPDATE CASCADE
       , PRIMARY KEY (person_id, lng_code)
) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

COMMENT ON TABLE persons_languages IS '
Priority of use (field "lng_personal_priority"), the bigger, the more preferable by this person.
Field "lng_skill" is constrainted by values range [-100..100], the same is for field "lng_personal_priority".
';

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE persons_languages TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT SELECT                         ON TABLE persons_languages TO user_db<<$db_name$>>_app<<$app_name$>>_data_reader;

-------------------------------------------------------------------------------

CREATE TABLE persons_names (
        person_id integer NOT NULL
      , PRIMARY KEY (person_id, lng_of_name)
      , FOREIGN KEY (person_id)   REFERENCES persons(person_id) ON DELETE CASCADE  ON UPDATE CASCADE
      , FOREIGN KEY (lng_of_name) REFERENCES languages(code_id) ON UPDATE CASCADE  ON DELETE RESTRICT
      , FOREIGN KEY (entity)      REFERENCES codes(code_id)     ON DELETE RESTRICT ON UPDATE CASCADE
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

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE persons_names TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT SELECT                         ON TABLE persons_names TO user_db<<$db_name$>>_app<<$app_name$>>_data_reader;

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

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE contacts TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT SELECT                         ON TABLE contacts TO user_db<<$db_name$>>_app<<$app_name$>>_data_reader;

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
      , FOREIGN KEY (contact_id)  REFERENCES contacts(contact_id) ON DELETE CASCADE  ON UPDATE CASCADE
      , FOREIGN KEY (lng_of_name) REFERENCES languages(code_id)   ON UPDATE CASCADE  ON DELETE RESTRICT
      , FOREIGN KEY (entity)      REFERENCES codes(code_id)       ON DELETE RESTRICT ON UPDATE CASCADE
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

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE contacts_names TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT SELECT                         ON TABLE contacts_names TO user_db<<$db_name$>>_app<<$app_name$>>_data_reader;

CREATE INDEX names_of_contacts_idx ON contacts_names(name) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>_idxs;

\echo NOTICE >>>>> structure.init.sql [END]

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

-- Sometimes we want to insert some data, before creating triggers.

\i triggers.init.sql
\i functions.init.sql
\i ../data/data.init.sql

