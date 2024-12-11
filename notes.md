- It is possible to ship a plain text dump in image that inherits postgis docker image
  - PROS : populate the db is fast !
  - CONS : the dump is not compressed and the image will be big ! maybe will exceed the limit of github container hub

```docker
FROM postgis/postgis:17-3.5

ENV POSTGRES_USER postgres
ENV POSTGRES_PASSWORD postgres
ENV POSTGRES_DB geonature2db

COPY create_user.sql /docker-entrypoint-initdb.d/01.sql
COPY geonature_develop.sql /docker-entrypoint-initdb.d/02.sql
```

- It is possible to dump the database during the build of the docker image. Thanks to https://cadu.dev/creating-a-docker-image-with-database-preloaded/
  - PROS: database is ready to go !
  - CONS: the dump is not compressed and the image will be big ! maybe will exceed the limit of github container hub... but ! will make fastest development

```docker
FROM postgis/postgis:17-3.5 as dumper

COPY create_user.sql /docker-entrypoint-initdb.d/01.sql
COPY geonature_develop.sql /docker-entrypoint-initdb.d/02.sql

RUN ["sed", "-i", "s/exec \"$@\"/echo \"skipping...\"/", "/usr/local/bin/docker-entrypoint.sh"]

ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=postgres
ENV POSTGRES_DB geonature2db
ENV PGDATA=/data

RUN ["/usr/local/bin/docker-entrypoint.sh", "postgres"]

# final build stage
FROM postgis/postgis:17-3.5

COPY --from=dumper /data $PGDATA
```

voir envsubst pour faire des templates en bash
