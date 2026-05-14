-- trip-svc: postgres user, database, and permissions.
-- Idempotent — safe to re-run.
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'trip_svc') THEN
    CREATE USER trip_svc;
  END IF;
END
$$;

SELECT 'CREATE DATABASE katisha_trips OWNER trip_svc'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'katisha_trips')\gexec

GRANT ALL PRIVILEGES ON DATABASE katisha_trips TO trip_svc;

SELECT 'CREATE DATABASE katisha_trips_shadow OWNER trip_svc'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'katisha_trips_shadow')\gexec

GRANT ALL PRIVILEGES ON DATABASE katisha_trips_shadow TO trip_svc;
