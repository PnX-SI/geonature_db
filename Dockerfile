ARG pg_image_version

FROM postgis/postgis:${pg_image_version}

ARG pg_user="geonatadmin"
ARG pg_password="geonatadmin"
ARG pg_database="geonature2db"
ARG dump_filename

ENV POSTGRES_USER=${pg_user}
ENV POSTGRES_PASSWORD=${pg_password}
ENV POSTGRES_DB=${pg_database}

COPY ${dump_filename} /tmp/pgdump.pg
COPY --chmod=755 wait-for-pg-isready.sh /tmp/wait-for-pg-isready.sh


RUN set -e && \
    nohup bash -c "docker-entrypoint.sh postgres &" && \
    /tmp/wait-for-pg-isready.sh && \
    pg_restore -v -c -U ${POSTGRES_USER} -d ${POSTGRES_DB} /tmp/pgdump.pg && \
    rm -rf /tmp/pgdump.pg ; exit 0
