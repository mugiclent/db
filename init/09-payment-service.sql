-- payment-svc: postgres user, database, permissions.
-- Idempotent — safe to re-run.
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'payment_svc') THEN
    CREATE USER payment_svc;
  END IF;
END
$$;

SELECT 'CREATE DATABASE katisha_payments OWNER payment_svc'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'katisha_payments')\gexec

GRANT ALL PRIVILEGES ON DATABASE katisha_payments TO payment_svc;

SELECT 'CREATE DATABASE katisha_payments_shadow OWNER payment_svc'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'katisha_payments_shadow')\gexec

GRANT ALL PRIVILEGES ON DATABASE katisha_payments_shadow TO payment_svc;
