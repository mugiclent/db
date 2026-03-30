FROM postgres:17

# -----------------------------------------------------------------------
# ONLY third-party extensions need an OS package here.
# Built-in extensions (pg_trgm, unaccent, fuzzystrmatch, uuid-ossp,
# pgcrypto …) ship with PostgreSQL — no package needed, just SQL.
#
# To add a third-party extension:
#   1. Add its apt package below
#   2. Add CREATE EXTENSION in init/01-extensions.sql
#   Find packages with: apt-cache search postgresql-17
# -----------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-17-pgvector \
    && rm -rf /var/lib/apt/lists/*
