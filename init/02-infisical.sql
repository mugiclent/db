-- Creates the infisical database user.
-- Runs once when the db_data volume is first initialised.
--
-- NOTE: CREATE DATABASE cannot run here — PostgreSQL wraps init scripts in a
-- transaction block and CREATE DATABASE is not allowed inside transactions.
-- The infisical database and password are handled by the infisical deploy pipeline.
CREATE USER infisical;
