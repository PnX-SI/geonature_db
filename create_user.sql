CREATE ROLE geonatadmin WITH LOGIN PASSWORD 'geonatadmin';

GRANT geonatadmin TO postgres;

ALTER ROLE geonatadmin WITH SUPERUSER;