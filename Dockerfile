#####################
# BUILDING PARAMETERS
#####################

ARG pg_user="geonatadmin"
ARG pg_password="geonatadmin"   
ARG pg_database="geonature2db"
ARG GEONATURE_VERSION=2.15.2

##################################
# BUILD EXTERNAL GEONATURE MODULES
##################################
FROM python:3.11-bookworm AS build

ENV PIP_ROOT_USER_ACTION=ignore
RUN --mount=type=cache,target=/root/.cache \
    pip install --upgrade pip setuptools wheel


FROM build AS build-export
WORKDIR /build/
COPY ./gn_module_export .
RUN python setup.py bdist_wheel

FROM build AS build-dashboard
WORKDIR /build/
COPY ./gn_module_dashboard .
RUN python setup.py bdist_wheel

FROM build AS build-monitoring
WORKDIR /build/
COPY ./gn_module_monitoring .
RUN python setup.py bdist_wheel

###################################
# GET CORE GEONATURE BACKEND WHEELS
###################################
FROM ghcr.io/pnx-si/geonature-backend:${GEONATURE_VERSION}-wheels AS geonatureback

###########################
# POPULATION DATABASE STAGE
###########################
FROM python:3.9-bookworm AS build_db

ARG pg_user
ARG pg_password
ARG pg_database
ENV POSTGRES_USER=${pg_user}
ENV POSTGRES_PASSWORD=${pg_password}
ENV POSTGRES_DB=${pg_database}

ENV GEONATURE_SQLALCHEMY_DATABASE_URI="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost/${POSTGRES_DB}"
ENV GEONATURE_SECRET_KEY="4648d84234380181c4448c69951f29854de6250712289a75bb9686c07dddca8e"
ENV GEONATURE_CONFIG_FILE="/geonature_config.toml"

# Setup POSTGRES + POSTGIS + MINIMU SYSTEM REQUIREMENTS
RUN  apt update &&  apt install postgresql-postgis postgis libpq-dev libgdal-dev libffi-dev -y && \
    apt-get clean &&  apt-get autoclean &&  apt-get autoremove &&  rm -rf /var/lib/apt/lists/* 

# RECOVER GEONATURE BACKEND WHEELS
COPY --from=geonatureback /dist/geonature/*.whl /dist/
# RECOVER GEONATURE MODULE WHEELS
COPY --from=build-export /build/dist/*.whl /dist/
COPY --from=build-dashboard /build/dist/*.whl /dist/
COPY --from=build-monitoring /build/dist/*.whl /dist/

# RECOVER DATABASE MAIN POPULATION SCRIPT
COPY --from=geonatureback /populate_db.sh /populate_db.sh 

# INSTALL ALL WHEELS
WORKDIR /dist/
RUN pip install *.whl 

# INITIALISATION OF THE POSTGRES DATABASE
USER postgres
COPY init_db.sql /init_db.sql
RUN service postgresql start && \
    until pg_isready; do sleep 1; done && \
    createuser -s ${POSTGRES_USER} && \
    psql -c "ALTER USER ${POSTGRES_USER} WITH PASSWORD '${POSTGRES_PASSWORD}';" && \
    createdb -O ${POSTGRES_USER} ${POSTGRES_DB} && \
    psql ${POSTGRES_DB} -f /init_db.sql 

# GENERATE CONFIGURATION FILES
USER root
COPY ./geonature_config.toml.template geonature_config.toml.template
RUN sed -e "s/\$user_pg/${POSTGRES_USER}/g" \
    -e "s/\$password_pg/${POSTGRES_PASSWORD}/g" \
    -e "s/\$pg_port/5432/g" \
    -e "s/\$pg_database/${POSTGRES_DB}/g" \
    geonature_config.toml.template > /geonature_config.toml

COPY ./settings.ini.template settings.ini.template
RUN sed -e "s/\$user_pg/${POSTGRES_USER}/g" \
    -e "s/\$password_pg/${POSTGRES_PASSWORD}/g" \
    -e "s/\$pg_port/5432/g" \
    -e "s/\$pg_database/${POSTGRES_DB}/g" \
    settings.ini.template > settings.ini

RUN cat settings.ini > /populate_db_.sh
RUN cat /populate_db.sh >> /populate_db_.sh && chmod +x /populate_db_.sh

# FINALLY POPULATE THE DATABASE
RUN service postgresql start && \
    until pg_isready; do sleep 1; done && \
    bash -c "/populate_db_.sh" && \
    geonature upgrade-modules-db


#######################
# FINAL POSTGRES IMAGE
#######################
FROM postgis/postgis:15-3.3

LABEL org.opencontainers.image.authors="jacquesfize" \
    org.opencontainers.image.description="Populated PostgreSQL database for GeoNature" \
    org.opencontainers.image.documentation="https://github.com/jacquesfize/geonature_db_docker" \
    org.opencontainers.image.source="https://github.com/jacquesfize/geonature_db_docker" \
    org.opencontainers.image.title="GeoNature PostgreSQL Docker image" 
# org.opencontainers.image.url="https://hub.docker.com/r/pnxs/geonature-db"
ARG pg_password
ENV POSTGRES_PASSWORD=${pg_password}

COPY --from=build_db /var/lib/postgresql/15/main $PGDATA
RUN echo "host all all 0.0.0.0/0 trust" > ${PGDATA}/pg_hba.conf
RUN echo "listen_addresses = '*'" >> ${PGDATA}/postgresql.conf

