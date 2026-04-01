# katisha — db

PostgreSQL 17 database for the Katisha platform, running in Docker on the
`katisha-net` bridge network. Every configuration change is made in this
repo; GitHub Actions handles the rest automatically.

This service is the **single source of truth for all database provisioning**
on the platform. Every postgres user, database, and permission grant for every
other service lives in `init/`.

---

## How it works

```
push to main
    └─ GitHub Actions
           └─ SSH into server
                  ├─ git clone (first time) or git pull
                  ├─ write .env from secrets
                  ├─ docker compose up -d --build
                  │      ├─ rebuilds image if Dockerfile changed
                  │      ├─ recreates container if config changed
                  │      └─ leaves the db_data volume untouched
                  ├─ docker exec psql -f 01-extensions.sql   (idempotent)
                  ├─ docker exec psql -f 02-seaweedfs.sql    (idempotent)
                  ├─ docker exec psql -f 03-infisical.sql    (idempotent)
                  ├─ docker exec psql ALTER USER seaweedfs   (sets password)
                  └─ docker exec psql ALTER USER infisical   (sets password)
```

The volume is **never touched** by the pipeline. Only a manual
`docker compose down -v` would remove it.

---

## Repository layout

```
db/
├── Dockerfile                   # OS-level extension packages
├── docker-compose.yml           # container, volume, network wiring
├── config/
│   └── postgresql.conf          # all PostgreSQL tuning
├── init/                        # runs automatically on a fresh volume;
│   │                            # also re-run by the deploy workflow (idempotent)
│   ├── 01-extensions.sql        # platform extensions (pgvector, pg_trgm, ...)
│   ├── 02-seaweedfs.sql         # CDN: user, database, permissions
│   └── 03-infisical.sql         # secrets manager: user, database, permissions
├── .env.example
├── actions.env                  # GitHub Actions secrets reference
└── .github/workflows/deploy.yml
```

---

## Init script design

### Why one SQL file per service?

Each service that needs a database gets its own `.sql` file. This keeps
provisioning readable, reviewable, and version-controlled. Every script
is idempotent — safe to re-run on every deploy against an existing volume.

### Why no passwords in the SQL files?

Passwords are credentials, not structure. The SQL files create users **without
passwords** (`CREATE USER foo;`). The deploy workflow then runs
`ALTER USER foo WITH PASSWORD '...'` using GitHub secrets, keeping passwords
out of the repository entirely.

### Why not shell scripts?

Pure SQL is simpler and more readable. The one edge case is `CREATE DATABASE`,
which cannot run inside a PL/pgSQL `DO $$ ... $$` block (a transaction).
The workaround is the `\gexec` metacommand:

```sql
SELECT 'CREATE DATABASE foo OWNER bar'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'foo')\gexec
```

`\gexec` sends each row of the SELECT result as a SQL command. If the database
already exists the SELECT returns 0 rows and nothing happens. `\gexec` works
with `psql -f` (file mode) — the earlier issue with `\gexec` was specific to
`psql -c` (single command mode).

---

## GitHub Actions secrets

| Secret | Description | Why here and not Infisical? |
|---|---|---|
| `SERVER_HOST` | Server IP or hostname | Infrastructure — Infisical not up yet |
| `SERVER_USER` | SSH username | Infrastructure |
| `SERVER_SSH_KEY` | Private SSH key | Infrastructure |
| `POSTGRES_USER` | Superuser name | db starts before Infisical is up |
| `POSTGRES_PASSWORD` | Superuser password | db starts before Infisical is up |
| `POSTGRES_DB` | Default database name | db starts before Infisical is up |
| `INFISICAL_DB_PASSWORD` | Password for the `infisical` postgres user | db starts before Infisical — cannot fetch from it |
| `SEAWEED_DB_PASSWORD` | Password for the `seaweedfs` postgres user | db starts before Infisical — also stored in Infisical `/cdn` |

**Why are service passwords GitHub secrets here instead of Infisical?**
The db service must be running *before* Infisical starts (Infisical uses
postgres as its backend). This is a bootstrapping dependency — we cannot ask
Infisical for credentials when provisioning the db itself. Once the db is up
and Infisical is deployed, all other services fetch credentials from Infisical
at runtime.

---

## Adding a new service database

1. Create `init/NN-servicename.sql` following the pattern in `02-seaweedfs.sql`.
2. Add `MYSERVICE_DB_PASSWORD` to this repo's GitHub Actions secrets.
3. Add an `ALTER USER myservice WITH PASSWORD '...'` call to the deploy workflow.
4. Store the same password in Infisical under the service's own path so it can
   fetch it at runtime.

---

## Tuning PostgreSQL

Edit [config/postgresql.conf](config/postgresql.conf), commit, and push.

| Setting | Rule of thumb |
|---|---|
| `shared_buffers` | ~25% of server RAM |
| `effective_cache_size` | ~75% of server RAM |
| `work_mem` | RAM / (max_connections * 2) |

---

## Local development

```bash
cp .env.example .env
docker compose up -d --build
```

---

## Network

Container name `db`, port `5432` on `katisha-net`. Not exposed to the host.

```
postgresql://user:password@db:5432/dbname
```

Timezone: `Africa/Kigali` (UTC+2, CAT).
