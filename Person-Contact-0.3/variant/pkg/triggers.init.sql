-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> triggers.init.sql [BEGIN]

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- make sure recursive persons selfreferences from contacts won't disturb deletion procedure
CREATE OR REPLACE FUNCTION person_ondelete() RETURNS trigger
LANGUAGE plpgsql
AS $personal_contacts_onmodify$ -- before delete
BEGIN
        DELETE FROM sch_<<$app_name$>>.contacts WHERE person_id = OLD.person_id;
        RETURN OLD;
END;
$personal_contacts_onmodify$;

CREATE TRIGGER tri_person_ondelete BEFORE DELETE ON persons
    FOR EACH ROW EXECUTE PROCEDURE person_ondelete();

------------------

CREATE OR REPLACE FUNCTION personal_contacts_onmodify() RETURNS trigger
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
LANGUAGE plpgsql
AS $personal_contacts_onmodify$ -- upd, ins
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
$personal_contacts_onmodify$;

CREATE TRIGGER tri_personal_contacts_onmodify AFTER INSERT OR UPDATE ON sch_<<$app_name$>>.contacts
    FOR EACH ROW EXECUTE PROCEDURE personal_contacts_onmodify();

------------------

-- used for triggers by modules in contact_instances
CREATE OR REPLACE FUNCTION personal_contact_detail_onmodify() RETURNS trigger
LANGUAGE plpgsql
AS $personal_contact_detail_onmodify$ -- upd, ins
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

        code:= sch_<<$app_name$>>.get_code(FALSE, sch_<<$app_name$>>.make_acodekeyl_byid(cont.contact_type));
        tn:= code.additional_field_1;

        IF (TG_TABLE_NAME :: regtype) IS DISTINCT FROM tn THEN
                RAISE EXCEPTION 'An error occurred, when an % operation attempted on a contact detail table "%" with contact ID "%". The contact is of different type (according to "contacts.contact_type" field), it''s details are to be stored in different contact-detail table - in "%".', TG_OP, TG_TABLE_NAME, NEW.contact_id, tn;
        END IF;

        RETURN NEW;
END;
$personal_contact_detail_onmodify$;

CREATE OR REPLACE FUNCTION personal_contact_detail_onderef() RETURNS trigger
LANGUAGE plpgsql
AS $personal_contact_detail_onderef$ -- upd, del
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
$personal_contact_detail_onderef$;

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> triggers.init.sql [END]