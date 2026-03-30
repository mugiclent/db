-- Creates the infisical database user and database.
-- Runs automatically once when the db_data volume is first initialised.
-- IF NOT EXISTS guards make it safe to re-run via the deploy pipeline.

-- The password is set by the deploy pipeline after container start via:
--   docker exec db psql -U bikaze -c "ALTER USER infisical WITH PASSWORD '...'"
-- This ensures the real password (from secrets) is always in sync.
CREATE USER infisical;
CREATE DATABASE infisical OWNER infisical;
GRANT ALL PRIVILEGES ON DATABASE infisical TO infisical;
