-- user-service: postgres user, database, and permissions.
-- Idempotent — safe to re-run on every deploy via docker exec.
--
-- NOTE: Password is NOT set here. The db deploy workflow sets it via
--   ALTER USER user_svc WITH PASSWORD '...'
-- using the USER_SVC_DB_PASSWORD GitHub secret, so it never touches the repo.

-- Create user (no password — set by deploy workflow)
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'user_svc') THEN
    CREATE USER user_svc;
  END IF;
END
$$;

-- Create database (cannot run inside a DO block — use \gexec trick instead)
SELECT 'CREATE DATABASE katisha_users OWNER user_svc'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'katisha_users')\gexec

GRANT ALL PRIVILEGES ON DATABASE katisha_users TO user_svc;
