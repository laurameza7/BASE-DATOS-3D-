# UCC Pasto 3D — Base de datos

Repositorio de la **base de datos** del proyecto *UCC Pasto 3D* (Patrones de Software).
Motor: **PostgreSQL**, desplegado en la nube con **Neon** (plan gratuito).

## Estructura

```
migrations/
  V1__esquema.sql          -> tablas: edificio, lugar, programa, pregunta_frecuente, conversacion
  V2__datos_iniciales.sql  -> datos del campus (bloques, oficinas, programas, preguntas frecuentes)
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

> Nota: la ubicación de los bloques es un modelo esquemático del campus. Ajustar coordenadas,
> programas y horarios con información oficial de la universidad.


