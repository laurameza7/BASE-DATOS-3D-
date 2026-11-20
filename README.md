# UCC Pasto 3D — Base de datos

Repositorio de la **base de datos** del proyecto *UCC Pasto 3D* (Patrones de Software).
Motor: **PostgreSQL**, desplegado en la nube con **Neon** (plan gratuito).

## Estructura

```
migrations/
  V1__esquema.sql          -> tablas: edificio, lugar, programa, pregunta_frecuente, conversacion
  V2__datos_iniciales.sql  -> datos del campus (bloques, oficinas, programas, preguntas frecuentes)
  V3__usuarios.sql         -> usuarios (contraseña nunca guardada: solo BCrypt de su SHA-256) y conversaciones por usuario
  V4__espacios_de_los_videos.sql -> facultades, laboratorios y espacios de los bloques A y B registrados en video,
                              y la facultad (lugar) de cada programa
  V5__ajustes_recorrido.sql -> paso subterráneo B (sótano 2) ↔ A (Piso 0) e índices para el historial
pruebas/verificar.sql      -> pruebas de datos, integridad y seguridad (ver abajo)
diagrama/modelo-er.md      -> modelo entidad-relación
.github/workflows/desplegar-bd.yml -> aplica las migraciones en Neon en cada push a main
.github/workflows/pruebas.yml      -> prueba las migraciones en un PostgreSQL 16 vacío en cada push
```

## Despliegue

1. Crear el proyecto en https://neon.tech y copiar la *connection string* (`postgresql://usuario:clave@host/neondb?sslmode=require`).
2. En este repositorio: **Settings → Secrets and variables → Actions → New repository secret**
   - Nombre: `DATABASE_URL` — Valor: la connection string de Neon.
3. Hacer push a `main` (o ejecutar el workflow manualmente en la pestaña **Actions**). El workflow crea las tablas y carga los datos.

## Cómo agregar información

Para que la IA sepa algo nuevo (un programa, una oficina, una pregunta frecuente) basta con
agregarlo en una nueva migración (`V6__...sql`) y hacer push. Las migraciones deben ser **idempotentes**
(`IF NOT EXISTS`, `DELETE` + `INSERT`, `UPDATE`), porque el despliegue las vuelve a ejecutar todas.

## Pruebas

En cada push, GitHub Actions levanta un PostgreSQL 16 vacío, aplica las migraciones **dos veces**
(para comprobar que se pueden repetir sin error) y corre `pruebas/verificar.sql`, que revisa:

| # | Qué comprueba |
|---|---|
| 1 | Hay edificios, al menos 60 lugares, 19 programas y las preguntas frecuentes |
| 2 | Bloque A con 6 pisos y sótano, Bloque B con 7 pisos y 2 sótanos |
| 3 | Ningún lugar está en un piso que no exista en su edificio |
| 4 | No hay lugares repetidos dentro de un mismo bloque |
| 5–6 | Cada programa de una facultad apunta a su facultad dentro del campus |
| 7 | La tabla `usuario` no tiene columnas para la contraseña ni su huella, solo `hash_clave` (BCrypt) |
| 8 | No se puede registrar dos veces el mismo correo |
| 9 | Existen los índices que usa el backend |

Para correrlas en el computador:

```bash
for f in $(ls migrations/*.sql | sort -V); do psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$f"; done
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f pruebas/verificar.sql
```

> Nota: los datos se levantan con fotos y recorridos del campus. Completar por piso a medida que se verifiquen;
> lo que no esté verificado se deja vacío en vez de inventarlo.


