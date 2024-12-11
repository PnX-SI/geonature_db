FROM postgis/postgis:17-3.5-alpine AS dumper

ARG dump_filename

COPY create_user.sql /docker-entrypoint-initdb.d/01.sql
COPY $dump_filename /docker-entrypoint-initdb.d/02.sql

RUN ["sed", "-i", "s/exec \"$@\"/echo \"skipping...\"/", "/usr/local/bin/docker-entrypoint.sh"]

ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=postgres
ENV POSTGRES_DB geonature2db
ENV PGDATA=/data

RUN ["/usr/local/bin/docker-entrypoint.sh", "postgres"]

# final build stage
FROM postgis/postgis:17-3.5-alpine
COPY --from=dumper /data $PGDATA
