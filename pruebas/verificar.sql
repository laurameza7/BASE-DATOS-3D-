-- =====================================================================
-- Pruebas de la base de datos: se ejecutan después de aplicar las migraciones.
-- Cada bloque DO lanza un error (y el flujo falla) si algo no se cumple.
-- Uso: psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f pruebas/verificar.sql
-- =====================================================================

-- 1. Cantidad mínima de datos del campus
DO $$ BEGIN
  IF (SELECT COUNT(*) FROM edificio) < 6 THEN RAISE EXCEPTION 'Faltan edificios'; END IF;
  IF (SELECT COUNT(*) FROM lugar) < 60 THEN RAISE EXCEPTION 'Faltan lugares (hay %)', (SELECT COUNT(*) FROM lugar); END IF;
  IF (SELECT COUNT(*) FROM programa) < 19 THEN RAISE EXCEPTION 'Faltan programas'; END IF;
  IF (SELECT COUNT(*) FROM pregunta_frecuente) < 5 THEN RAISE EXCEPTION 'Faltan preguntas frecuentes'; END IF;
END $$;

-- 2. Los dos bloques con interior: Bloque A (6 pisos y sótano) y Bloque B (7 pisos, 2 sótanos)
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM edificio WHERE codigo = 'A' AND pisos = 6 AND sotanos >= 1) THEN RAISE EXCEPTION 'Bloque A mal registrado'; END IF;
  IF NOT EXISTS (SELECT 1 FROM edificio WHERE codigo = 'B' AND pisos = 7 AND sotanos = 2) THEN RAISE EXCEPTION 'Bloque B mal registrado'; END IF;
END $$;

-- 3. Cada lugar está en un piso que existe en su edificio
DO $$ DECLARE malo TEXT; BEGIN
  SELECT string_agg(l.nombre || ' (' || e.codigo || ' piso ' || l.piso || ')', ', ') INTO malo
    FROM lugar l JOIN edificio e ON e.id = l.edificio_id
   WHERE l.piso > GREATEST(e.pisos, 1) OR l.piso < -e.sotanos OR (l.piso = 0 AND e.pisos > 0);
  IF malo IS NOT NULL THEN RAISE EXCEPTION 'Lugares en pisos que no existen: %', malo; END IF;
END $$;

-- 4. No hay lugares repetidos dentro de un mismo edificio
DO $$ DECLARE malo TEXT; BEGIN
  SELECT string_agg(nombre, ', ') INTO malo FROM (
    SELECT nombre FROM lugar GROUP BY edificio_id, nombre HAVING COUNT(*) > 1) d;
  IF malo IS NOT NULL THEN RAISE EXCEPTION 'Lugares repetidos: %', malo; END IF;
END $$;

-- 5. Todos los programas de pregrado y especialización tienen su facultad ubicada en el campus
DO $$ DECLARE malo TEXT; BEGIN
  SELECT string_agg(nombre, ', ') INTO malo FROM programa
   WHERE lugar_id IS NULL AND facultad LIKE 'Facultad de %';
  IF malo IS NOT NULL THEN RAISE EXCEPTION 'Programas sin facultad ubicada: %', malo; END IF;
  IF EXISTS (SELECT 1 FROM programa WHERE nivel NOT IN ('PREGRADO', 'ESPECIALIZACION', 'MAESTRIA', 'TECNICO')) THEN
    RAISE EXCEPTION 'Hay programas con un nivel desconocido'; END IF;
END $$;

-- 6. La facultad a la que apunta cada programa es la suya
DO $$ DECLARE malo TEXT; BEGIN
  SELECT string_agg(p.nombre || ' → ' || l.nombre, ', ') INTO malo
    FROM programa p JOIN lugar l ON l.id = p.lugar_id
   WHERE l.nombre <> p.facultad;
  IF malo IS NOT NULL THEN RAISE EXCEPTION 'Programas apuntando a otra facultad: %', malo; END IF;
END $$;

-- 7. Seguridad: la tabla de usuarios no tiene ninguna columna para la contraseña en texto plano
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
              WHERE table_name = 'usuario' AND column_name IN ('clave', 'contrasena', 'password', 'huella')) THEN
    RAISE EXCEPTION 'La tabla usuario no debe guardar la contraseña ni su huella';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'usuario' AND column_name = 'hash_clave') THEN
    RAISE EXCEPTION 'Falta la columna hash_clave (BCrypt)';
  END IF;
END $$;

-- 8. El correo de los usuarios es único (no se puede registrar dos veces)
DO $$ BEGIN
  INSERT INTO usuario (nombre, correo, hash_clave) VALUES ('Prueba', 'prueba.ci@ucc.edu.co', '$2a$10$x');
  BEGIN
    INSERT INTO usuario (nombre, correo, hash_clave) VALUES ('Prueba 2', 'prueba.ci@ucc.edu.co', '$2a$10$y');
    RAISE EXCEPTION 'Se pudo registrar dos veces el mismo correo';
  EXCEPTION WHEN unique_violation THEN NULL;
  END;
  DELETE FROM usuario WHERE correo = 'prueba.ci@ucc.edu.co';
END $$;

-- 9. Índices que usa el backend
DO $$ DECLARE i TEXT; BEGIN
  FOREACH i IN ARRAY ARRAY['idx_lugar_edificio', 'idx_programa_edificio', 'idx_conversacion_usuario', 'idx_programa_lugar', 'idx_conversacion_fecha'] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = i) THEN RAISE EXCEPTION 'Falta el índice %', i; END IF;
  END LOOP;
END $$;

SELECT 'edificios' AS tabla, COUNT(*) FROM edificio
UNION ALL SELECT 'lugares', COUNT(*) FROM lugar
UNION ALL SELECT 'programas', COUNT(*) FROM programa
UNION ALL SELECT 'preguntas frecuentes', COUNT(*) FROM pregunta_frecuente;
