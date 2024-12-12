ARG pg_image_version
ARG pg_user=postgres
ARG pg_password=postgres
ARG pg_database=geonature2db

FROM postgis/postgis:${pg_image_version} AS dumper

ARG dump_filename

COPY create_user.sql /docker-entrypoint-initdb.d/01.sql
COPY $dump_filename /docker-entrypoint-initdb.d/02.sql

RUN ["sed", "-i", "s/exec \"$@\"/echo \"skipping...\"/", "/usr/local/bin/docker-entrypoint.sh"]

ENV POSTGRES_USER=${pg_user}
ENV POSTGRES_PASSWORD=${pg_password}
ENV POSTGRES_DB=${pg_database}
ENV PGDATA=/data

RUN ["/usr/local/bin/docker-entrypoint.sh", "postgres"]

# final build stage
FROM postgis/postgis:17-3.5-alpine
COPY --from=dumper /data $PGDATA
