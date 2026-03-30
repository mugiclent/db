-- All statements use IF NOT EXISTS — this file is safe to re-run at any time.
-- GitHub Actions runs it on every deploy (see deploy.yml), so new extensions
-- added here are activated automatically on the next push without any manual step.
--
-- Third-party extensions (marked below) also need an OS package in the Dockerfile.
-- Built-in extensions need this file only.

-- Built-in: full-text search helpers
CREATE EXTENSION IF NOT EXISTS pg_trgm;        -- trigram similarity
CREATE EXTENSION IF NOT EXISTS unaccent;        -- accent-insensitive search
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;   -- soundex / levenshtein

-- Built-in: general purpose
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";     -- uuid_generate_v4()
CREATE EXTENSION IF NOT EXISTS pgcrypto;        -- gen_random_uuid(), crypt()

-- Third-party: also requires postgresql-17-pgvector in Dockerfile
CREATE EXTENSION IF NOT EXISTS vector;
