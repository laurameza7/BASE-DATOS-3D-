-- =====================================================================
-- V0 · Upgrade from the first version of the schema (Spanish names) to the
--      current one (English names). It runs before V1 on every deployment and
--      does nothing on a new database or once the upgrade has been applied.
--
--  * app_user and conversation keep their rows: the tables and columns are renamed.
--  * building, place, program and faq are dropped: V2 and V4 reload them on every run.
-- =====================================================================

DO $$
DECLARE
    r RECORD;
BEGIN
    -- ---------------------------------------------------------------- users
    IF to_regclass('public.usuario') IS NOT NULL AND to_regclass('public.app_user') IS NULL THEN
        ALTER TABLE usuario RENAME TO app_user;
        ALTER TABLE app_user RENAME COLUMN nombre         TO name;
        ALTER TABLE app_user RENAME COLUMN correo         TO email;
        ALTER TABLE app_user RENAME COLUMN hash_clave     TO password_hash;
        ALTER TABLE app_user RENAME COLUMN rol            TO role;
        ALTER TABLE app_user RENAME COLUMN creado_en      TO created_at;
        ALTER TABLE app_user RENAME COLUMN ultimo_ingreso TO last_login;
        ALTER TABLE app_user ALTER COLUMN role SET DEFAULT 'STUDENT';
        UPDATE app_user SET role = CASE role WHEN 'ESTUDIANTE' THEN 'STUDENT' WHEN 'VISITANTE' THEN 'VISITOR' ELSE role END;
    END IF;

    -- ---------------------------------------------------------------- conversations
    IF to_regclass('public.conversacion') IS NOT NULL AND to_regclass('public.conversation') IS NULL THEN
        ALTER TABLE conversacion RENAME TO conversation;
        ALTER TABLE conversation RENAME COLUMN pregunta  TO question;
        ALTER TABLE conversation RENAME COLUMN respuesta TO answer;
        ALTER TABLE conversation RENAME COLUMN proveedor TO provider;
        ALTER TABLE conversation RENAME COLUMN creado_en TO created_at;
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'conversation' AND column_name = 'usuario_id') THEN
            ALTER TABLE conversation RENAME COLUMN usuario_id TO user_id;
        END IF;
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'conversation' AND column_name = 'accion') THEN
            ALTER TABLE conversation RENAME COLUMN accion TO action;
            UPDATE conversation SET action = CASE action
                WHEN 'SALUDO'        THEN 'GREETING'
                WHEN 'VER_PROGRAMAS' THEN 'SHOW_PROGRAMS'
                WHEN 'IR_PROGRAMA'   THEN 'GO_TO_PROGRAM'
                WHEN 'IR_LUGAR'      THEN 'GO_TO_PLACE'
                WHEN 'IR_EDIFICIO'   THEN 'GO_TO_BUILDING'
                ELSE action END;
        END IF;
    END IF;

    -- Constraints, indexes and identity sequences that still have Spanish names
    FOR r IN SELECT conname, conrelid::regclass AS table_name FROM pg_constraint
              WHERE conrelid IN (to_regclass('public.app_user'), to_regclass('public.conversation'))
                AND (conname LIKE 'usuario%' OR conname LIKE 'conversacion%') LOOP
        EXECUTE format('ALTER TABLE %s RENAME CONSTRAINT %I TO %I', r.table_name, r.conname,
            replace(replace(replace(replace(r.conname, 'usuario_id', 'user_id'), 'correo', 'email'), 'usuario', 'app_user'), 'conversacion', 'conversation'));
    END LOOP;
    ALTER INDEX IF EXISTS idx_conversacion_usuario RENAME TO idx_conversation_user;
    ALTER INDEX IF EXISTS idx_conversacion_fecha   RENAME TO idx_conversation_date;
    ALTER SEQUENCE IF EXISTS usuario_id_seq      RENAME TO app_user_id_seq;
    ALTER SEQUENCE IF EXISTS conversacion_id_seq RENAME TO conversation_id_seq;

    -- ---------------------------------------------------------------- campus catalog
    DROP TABLE IF EXISTS programa, lugar, pregunta_frecuente, edificio CASCADE;
END $$;
