DO
$do$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles
      WHERE rolname = 'app') THEN
      CREATE ROLE app WITH LOGIN PASSWORD 'changethis123';
   END IF;
END
$do$;

CREATE DATABASE app;

GRANT ALL PRIVILEGES ON DATABASE app TO app;