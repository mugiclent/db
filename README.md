# katisha — db

PostgreSQL 17 database for the Katisha platform, running in Docker on the
`katisha-net` bridge network. Every configuration change is made in this
repo; GitHub Actions handles the rest automatically.

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
                  └─ docker exec psql -f 01-extensions.sql
                         └─ activates any new extensions (idempotent)
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
├── init/
│   └── 01-extensions.sql        # CREATE EXTENSION statements (idempotent)
├── .env.example                 # template — copy to .env for local dev
├── .github/
│   └── workflows/
│       └── deploy.yml           # CI/CD pipeline
└── README.md
```

---

## Making changes

### Tuning PostgreSQL

Edit [config/postgresql.conf](config/postgresql.conf), commit, and push.
The container is recreated automatically on the next deploy; the data volume
is not affected.

Key values to adjust per server size:

| Setting | Rule of thumb |
|---|---|
| `shared_buffers` | ~25 % of server RAM |
| `effective_cache_size` | ~75 % of server RAM |
| `work_mem` | `RAM / (max_connections * 2)` |

### Adding a built-in extension

Built-in extensions ship with PostgreSQL and need no OS package. Just add a
line to [init/01-extensions.sql](init/01-extensions.sql):

```sql
CREATE EXTENSION IF NOT EXISTS pg_trgm;
```

Commit and push. The pipeline re-runs the file on every deploy — the
`IF NOT EXISTS` guard makes it safe to re-run against an existing database.

### Adding a third-party extension

Third-party extensions (e.g. pgvector) also need an OS package in the image.
Two steps:

1. Add the apt package to [Dockerfile](Dockerfile):

```dockerfile
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-17-pgvector \
    postgresql-17-your-new-extension \
    && rm -rf /var/lib/apt/lists/*
```

2. Add the activation line to [init/01-extensions.sql](init/01-extensions.sql):

```sql
CREATE EXTENSION IF NOT EXISTS your_extension;
```

Commit and push. The image is rebuilt and the extension is activated
automatically.

Find available packages on the server with:

```bash
apt-cache search postgresql-17
```

---

## GitHub Actions secrets

Set these under **Settings → Secrets and variables → Actions** in the repo.

| Secret | Description |
|---|---|
| `SERVER_HOST` | IP address or hostname of the production server |
| `SERVER_USER` | SSH username (must be in the `docker` group) |
| `SERVER_SSH_KEY` | Private SSH key (the server must have the matching public key in `~/.ssh/authorized_keys`) |
| `POSTGRES_USER` | Database superuser name |
| `POSTGRES_PASSWORD` | Database superuser password |
| `POSTGRES_DB` | Default database name |

`GITHUB_TOKEN` is injected automatically by GitHub Actions — do not add it manually.

---

## One-time server setup

Run this once on the server before the first deploy:

```bash
# Create the shared Docker network (shared with all Katisha services)
docker network create katisha-net
```

That's it. The pipeline clones the repo and starts the container on the first push.

---

## Local development

```bash
cp .env.example .env
# edit .env with your local credentials
docker compose up -d --build
```

---

## Network & connectivity

The container is named `db` and listens on port `5432` inside `katisha-net`.
Other services connect using:

```
postgresql://user:password@db:5432/katisha
```

No port is exposed to the host. Only containers on `katisha-net` can reach it.

---

## Timezone

The database runs in `Africa/Kigali` (UTC+2, Central Africa Time).
All timestamps stored without a time zone offset are in CAT.
