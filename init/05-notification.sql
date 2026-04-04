-- notification-service: postgres user, database, and permissions.
-- Idempotent — safe to re-run on every deploy via docker exec.
--
-- NOTE: Password is NOT set here. The db deploy workflow sets it via
--   ALTER USER notification_svc WITH PASSWORD '...'
-- using the NOTIFICATION_DB_PASSWORD GitHub secret, so it never touches the repo.

-- Create user (no password — set by deploy workflow)
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'notification_svc') THEN
    CREATE USER notification_svc;
  END IF;
END
$$;

-- Create database (cannot run inside a DO block — use \gexec trick instead)
SELECT 'CREATE DATABASE notification_db OWNER notification_svc'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'notification_db')\gexec

GRANT ALL PRIVILEGES ON DATABASE notification_db TO notification_svc;
