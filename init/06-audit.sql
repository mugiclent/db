-- audit-service: postgres user, database, and permissions.
-- Idempotent — safe to re-run on every deploy via docker exec.
--
-- NOTE: Password is NOT set here. The db deploy workflow sets it via
--   ALTER USER audit_svc WITH PASSWORD '...'
-- using the AUDIT_DB_PASSWORD GitHub secret, so it never touches the repo.

-- Create user (no password — set by deploy workflow)
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'audit_svc') THEN
    CREATE USER audit_svc;
  END IF;
END
$$;

-- Create database (cannot run inside a DO block — use \gexec trick instead)
SELECT 'CREATE DATABASE audit_db OWNER audit_svc'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'audit_db')\gexec

GRANT ALL PRIVILEGES ON DATABASE audit_db TO audit_svc;
