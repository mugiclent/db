-- SeaweedFS filer: postgres user, database, and permissions.
-- Idempotent — safe to re-run on every deploy via docker exec.
--
-- NOTE: Password is NOT set here. The db deploy workflow sets it via
--   ALTER USER seaweedfs WITH PASSWORD '...'
-- using the SEAWEED_DB_PASSWORD GitHub secret, so it never touches the repo.

-- Create user (no password — set by deploy workflow)
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'seaweedfs') THEN
    CREATE USER seaweedfs;
  END IF;
END
$$;

-- Create database (cannot run inside a DO block — use \gexec trick instead)
SELECT 'CREATE DATABASE seaweed_metadata OWNER seaweedfs'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'seaweed_metadata')\gexec

GRANT ALL PRIVILEGES ON DATABASE seaweed_metadata TO seaweedfs;
