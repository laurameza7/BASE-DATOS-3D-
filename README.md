# UCC Pasto 3D — Database

**Database** repository of the *UCC Pasto 3D* project (Software Patterns course).
Engine: **PostgreSQL**, deployed in the cloud with **Neon** (free plan).

## Structure

```
migrations/
  V0__legacy_spanish_schema.sql  -> upgrades the first version of the schema (Spanish names) keeping users
  V1__schema.sql                 -> tables: building, place, program, faq, conversation
  V2__initial_data.sql           -> campus data (blocks, offices, programs, frequently asked questions)
  V3__users.sql                  -> app_user (the password is never stored: only BCrypt of its SHA-256)
                                    and conversations per user
  V4__video_spaces.sql           -> faculties, laboratories and spaces of blocks A and B recorded on video,
                                    and the faculty (place) of each program
  V5__walkthrough_adjustments.sql -> underground passage B (basement 2) ↔ A (Floor 0) and history indexes
tests/verify.sql                 -> data, integrity and security tests (see below)
diagram/er-model.md              -> entity-relationship model
.github/workflows/deploy-db.yml  -> applies the migrations on Neon on every push to main
.github/workflows/tests.yml      -> tests the migrations on an empty PostgreSQL 16 on every push
```

The schema (tables, columns and codes such as `UNDERGRADUATE` or `GO_TO_PLACE`) is in English.
Names, descriptions and answers stay in Spanish because they are shown to the users of the campus.

## Deployment

1. Create the project at https://neon.tech and copy the *connection string* (`postgresql://user:password@host/neondb?sslmode=require`).
2. In this repository: **Settings → Secrets and variables → Actions → New repository secret**
   - Name: `DATABASE_URL` — Value: the Neon connection string.
3. Push to `main` (or run the workflow manually in the **Actions** tab). The workflow creates the tables and loads the data.

## Adding information

To teach the assistant something new (a program, an office, a frequently asked question) add it in a new
migration (`V6__...sql`) and push. Migrations must be **idempotent** (`IF NOT EXISTS`, `DELETE` + `INSERT`,
`UPDATE`) because every deployment runs all of them again.

## Tests

On every push, GitHub Actions starts an empty PostgreSQL 16, applies the migrations **twice** (to check they
can be repeated without errors) and runs `tests/verify.sql`, which checks:

| # | What it checks |
|---|---|
| 1 | There are buildings, at least 60 places, 19 programs and the frequently asked questions |
| 2 | Block A has 6 floors and a basement, Block B has 7 floors and 2 basements |
| 3 | No place is on a floor that does not exist in its building |
| 4 | No place is repeated inside the same block |
| 5–6 | Every faculty program points to its own faculty on campus; levels and modalities are known codes |
| 7 | `app_user` has no column for the password or its fingerprint, only `password_hash` (BCrypt) |
| 8 | The same email cannot be registered twice |
| 9 | The indexes used by the backend exist |
| 10 | No table or column keeps a Spanish name from the first version of the schema |

To run them locally:

```bash
for f in $(ls migrations/*.sql | sort -V); do psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$f"; done
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f tests/verify.sql
```

> Note: the data comes from photos and walkthroughs of the campus. Anything that has not been verified
> is left empty instead of being invented.
