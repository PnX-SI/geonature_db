# Geonature DB

## Overview

This project provides a Dockerized PostgreSQL database for Geonature. The generated images are meant to be used for development and testing purposes.

## Prerequisites

- Docker installed on your system
- Git installed on your system

## Configuration

The following environment variables can be configured:

- `tag`: The tag of the Geonature DB image (default: `stock`)
- `version`: The version of the Geonature DB image (default: `2.15.2`)
- `user_pg`: The PostgreSQL username (default: `geonatadmin`)
- `password_pg`: The PostgreSQL password (default: `geonatadmin`)
- `pg_port`: The PostgreSQL port (default: `5432`)
- `pg_database`: The PostgreSQL database name (default: `geonature2db`)
- `monitoring_version`: The version of the monitoring module (default: `1.0.1`)
- `export_version`: The version of the export module (default: `1.7.2`)
- `dashboard_version`: The version of the dashboard module (default: `1.5.0`)

## Building the Image

To build the Geonature DB image, run the following command:

```bash
make build
```

This will clone the required Geonature modules, configure them, and build the Docker image.

## Building the Image from a Dump

To build the Geonature DB image from a dump file, run the following command:

```bash
make build_from_dump dump_filename=<path/to/dump/file>
```

This will build the Docker image using the specified dump file. Pratical, if you want to create a new image from your existing PostgreSQL database.

> [!WARNING]  
> When producing your dump file, it must be generated with `custom` format (https://www.postgresql.org/docs/current/app-pgdump.html)

## Running the Container

To run the Geonature DB container, run the following command:

```bash
make run
```

This will start a new container from the built image and map port 5432 on the host machine to port 5432 in the container.

Of course, it is better to use the generated image name with a `docker run` command.

## Running the Container from a Dump

To run the Geonature DB container from a dump file, run the following command:

```bash
make run_from_dump dump_filename=<path/to/dump/file>
```

This will start a new container from the built image and map port 5432 on the host machine to port 5432 in the container.

Of course, it is better to use the generated image name with a `docker run` command.

## Author

Jacques Fize (https://github.com/jacquesfize)
