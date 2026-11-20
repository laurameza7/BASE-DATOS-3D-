-- =====================================================================
-- Database tests: they run after the migrations have been applied.
-- Every DO block raises an error (and the workflow fails) if a rule is broken.
-- Usage: psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f tests/verify.sql
-- =====================================================================

-- 1. Minimum amount of campus data
DO $$ BEGIN
  IF (SELECT COUNT(*) FROM building) < 6 THEN RAISE EXCEPTION 'Missing buildings'; END IF;
  IF (SELECT COUNT(*) FROM place) < 60 THEN RAISE EXCEPTION 'Missing places (found %)', (SELECT COUNT(*) FROM place); END IF;
  IF (SELECT COUNT(*) FROM program) < 19 THEN RAISE EXCEPTION 'Missing programs'; END IF;
  IF (SELECT COUNT(*) FROM faq) < 5 THEN RAISE EXCEPTION 'Missing frequently asked questions'; END IF;
END $$;

-- 2. The two blocks with interiors: Block A (6 floors and basement) and Block B (7 floors, 2 basements)
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM building WHERE code = 'A' AND floors = 6 AND basements >= 1) THEN RAISE EXCEPTION 'Block A is wrong'; END IF;
  IF NOT EXISTS (SELECT 1 FROM building WHERE code = 'B' AND floors = 7 AND basements = 2) THEN RAISE EXCEPTION 'Block B is wrong'; END IF;
END $$;

-- 3. Every place is on a floor that exists in its building
DO $$ DECLARE wrong TEXT; BEGIN
  SELECT string_agg(p.name || ' (' || b.code || ' floor ' || p.floor || ')', ', ') INTO wrong
    FROM place p JOIN building b ON b.id = p.building_id
   WHERE p.floor > GREATEST(b.floors, 1) OR p.floor < -b.basements OR (p.floor = 0 AND b.floors > 0);
  IF wrong IS NOT NULL THEN RAISE EXCEPTION 'Places on floors that do not exist: %', wrong; END IF;
END $$;

-- 4. No repeated places inside the same building
DO $$ DECLARE wrong TEXT; BEGIN
  SELECT string_agg(name, ', ') INTO wrong FROM (
    SELECT name FROM place GROUP BY building_id, name HAVING COUNT(*) > 1) d;
  IF wrong IS NOT NULL THEN RAISE EXCEPTION 'Repeated places: %', wrong; END IF;
END $$;

-- 5. Every program of a faculty has its faculty located on campus, and levels/modalities are known codes
DO $$ DECLARE wrong TEXT; BEGIN
  SELECT string_agg(name, ', ') INTO wrong FROM program
   WHERE place_id IS NULL AND faculty LIKE 'Facultad de %';
  IF wrong IS NOT NULL THEN RAISE EXCEPTION 'Programs without a located faculty: %', wrong; END IF;
  IF EXISTS (SELECT 1 FROM program WHERE level NOT IN ('UNDERGRADUATE', 'SPECIALIZATION', 'MASTERS', 'TECHNICAL')) THEN
    RAISE EXCEPTION 'There are programs with an unknown level'; END IF;
  IF EXISTS (SELECT 1 FROM program WHERE modality NOT IN ('IN_PERSON', 'HYBRID', 'VIRTUAL')) THEN
    RAISE EXCEPTION 'There are programs with an unknown modality'; END IF;
END $$;

-- 6. The faculty each program points to is its own
DO $$ DECLARE wrong TEXT; BEGIN
  SELECT string_agg(p.name || ' → ' || pl.name, ', ') INTO wrong
    FROM program p JOIN place pl ON pl.id = p.place_id
   WHERE pl.name <> p.faculty;
  IF wrong IS NOT NULL THEN RAISE EXCEPTION 'Programs pointing to another faculty: %', wrong; END IF;
END $$;

-- 7. Security: the users table has no column for the plain password or its fingerprint
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
              WHERE table_name = 'app_user' AND column_name IN ('password', 'plain_password', 'fingerprint', 'clave', 'huella')) THEN
    RAISE EXCEPTION 'The app_user table must not store the password nor its fingerprint';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'app_user' AND column_name = 'password_hash') THEN
    RAISE EXCEPTION 'Missing column password_hash (BCrypt)';
  END IF;
END $$;

-- 8. The user email is unique (nobody can register twice)
DO $$ BEGIN
  INSERT INTO app_user (name, email, password_hash) VALUES ('Test', 'test.ci@ucc.edu.co', '$2a$10$x');
  BEGIN
    INSERT INTO app_user (name, email, password_hash) VALUES ('Test 2', 'test.ci@ucc.edu.co', '$2a$10$y');
    RAISE EXCEPTION 'The same email could be registered twice';
  EXCEPTION WHEN unique_violation THEN NULL;
  END;
  DELETE FROM app_user WHERE email = 'test.ci@ucc.edu.co';
END $$;

-- 9. Indexes used by the backend
DO $$ DECLARE i TEXT; BEGIN
  FOREACH i IN ARRAY ARRAY['idx_place_building', 'idx_program_building', 'idx_conversation_user', 'idx_program_place', 'idx_conversation_date'] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = i) THEN RAISE EXCEPTION 'Missing index %', i; END IF;
  END LOOP;
END $$;

-- 10. No table or column keeps a Spanish name from the first version of the schema
DO $$ DECLARE wrong TEXT; BEGIN
  SELECT string_agg(table_name || '.' || column_name, ', ') INTO wrong FROM information_schema.columns
   WHERE table_schema = 'public' AND (table_name IN ('edificio', 'lugar', 'programa', 'pregunta_frecuente', 'conversacion', 'usuario')
      OR column_name IN ('nombre', 'descripcion', 'piso', 'tipo', 'correo', 'hash_clave', 'creado_en'));
  IF wrong IS NOT NULL THEN RAISE EXCEPTION 'Spanish names left in the schema: %', wrong; END IF;
END $$;

SELECT 'buildings' AS "table", COUNT(*) FROM building
UNION ALL SELECT 'places', COUNT(*) FROM place
UNION ALL SELECT 'programs', COUNT(*) FROM program
UNION ALL SELECT 'faq', COUNT(*) FROM faq;
