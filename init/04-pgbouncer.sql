-- pgbouncer_auth: the dedicated user pgbouncer uses to run auth_query.
-- get_auth(): SECURITY DEFINER function that returns password hashes from pg_shadow,
--             allowing pgbouncer to authenticate any postgres user without superuser access.
--
-- This function lives in katisha-db because pgbouncer.ini sets auth_dbname = katisha-db,
-- meaning all auth_query calls are routed here regardless of which database the client
-- is connecting to. Only this one copy is ever needed.
--
-- Idempotent — safe to re-run on every deploy.
--
-- NOTE: Password is NOT set here. The db deploy workflow sets it via
--   ALTER USER pgbouncer_auth WITH PASSWORD '...'
-- using the PGBOUNCER_AUTH_PASSWORD GitHub secret, so it never touches the repo.

-- Create user (no password — set by deploy workflow)
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'pgbouncer_auth') THEN
    CREATE USER pgbouncer_auth;
  END IF;
END
$$;

-- SECURITY DEFINER runs as the function owner (the superuser who created it),
-- so pgbouncer_auth can read pg_shadow without being a superuser itself.
-- SET search_path prevents search_path injection attacks on SECURITY DEFINER functions.
CREATE OR REPLACE FUNCTION public.get_auth(p_usename text)
  RETURNS TABLE(username text, password text)
  LANGUAGE sql
  SECURITY DEFINER
  SET search_path = pg_catalog, public
AS $$
  SELECT usename::text, passwd::text
  FROM pg_catalog.pg_shadow
  WHERE usename = p_usename;
$$;

GRANT EXECUTE ON FUNCTION public.get_auth(text) TO pgbouncer_auth;
