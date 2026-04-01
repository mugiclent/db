-- Infisical secrets manager: postgres user, database, and permissions.
-- Idempotent — safe to re-run on every deploy via docker exec.
--
-- NOTE: Password is NOT set here. The db deploy workflow sets it via
--   ALTER USER infisical WITH PASSWORD '...'
-- using the INFISICAL_DB_PASSWORD GitHub secret, so it never touches the repo.

-- Create user (no password — set by deploy workflow)
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'infisical') THEN
    CREATE USER infisical;
  END IF;
END
$$;

-- Create database (cannot run inside a DO block — use \gexec trick instead)
SELECT 'CREATE DATABASE infisical OWNER infisical'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'infisical')\gexec

GRANT ALL PRIVILEGES ON DATABASE infisical TO infisical;
