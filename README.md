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
diagrama/modelo-er.md      -> modelo entidad-relación
.github/workflows/desplegar-bd.yml -> aplica las migraciones en Neon en cada push a main
```

## Despliegue

1. Crear el proyecto en https://neon.tech y copiar la *connection string* (`postgresql://usuario:clave@host/neondb?sslmode=require`).
2. En este repositorio: **Settings → Secrets and variables → Actions → New repository secret**
   - Nombre: `DATABASE_URL` — Valor: la connection string de Neon.
3. Hacer push a `main` (o ejecutar el workflow manualmente en la pestaña **Actions**). El workflow crea las tablas y carga los datos.

## Cómo agregar información

Para que la IA sepa algo nuevo (un programa, una oficina, una pregunta frecuente) basta con
agregarlo en `V2__datos_iniciales.sql` (o en una nueva migración `V3__...sql`) y hacer push.

> Nota: los datos se levantan con fotos y recorridos del campus. Completar por piso a medida que se verifiquen;
> lo que no esté verificado se deja vacío en vez de inventarlo.


