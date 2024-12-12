# Git version
tag ?= 2.15.0

# Version that will be indicated in the generate docker Image
version ?= latest

# Local PostgreSQL configuration
user_pg ?= postgres
password_pg ?= postgres
pg_port ?= 5432
pg_database ?= geonature2db

pg_image_version ?= 17-3.5-alpine
exit_status := $(shell ./docker_exists.sh $(pg_image_version))


check_if_postgis_image_exists:
	if [ $(exit_status) -eq 0 ]; then echo "Image postgis/postgis:${pg_image_version} exists"; else echo "Image postgis/postgis:${pg_image_version} does not exist"; fi; 

pull_geonature: 

	if [ ! -d GeoNature ]; then git clone https://github.com/PnX-SI/GeoNature.git; fi
	cd GeoNature && git fetch origin
	cd GeoNature && git checkout ${tag}
	cd GeoNature && git submodule init && git submodule update

generate_config:
	cat geonature_config.toml.template | sed "s/\$$user_pg/${user_pg}/g" | sed "s/\$$password_pg/${password_pg}/g" | sed "s/\$$pg_port/${pg_port}/g" | sed "s/\$$pg_database/${pg_database}/g" > geonature_config.toml
	cat settings.ini.template | sed "s/\$$user_pg/${user_pg}/g" | sed "s/\$$password_pg/${password_pg}/g" | sed "s/\$$pg_port/${pg_port}/g" | sed "s/\$$pg_database/${pg_database}/g" > settings.ini

install_geonature: pull_geonature generate_config

	cp settings.ini GeoNature/config/
	cp geonature_config.toml GeoNature/config/
	cd GeoNature && git fetch origin
	cd GeoNature && git checkout ${tag} && git submodule update
	cd GeoNature/install && ./01_install_backend.sh && ./03_create_db.sh && ./04_install_gn_modules.sh

dump:
	pg_dump -U geonatadmin -h localhost -p 5432 geonature2db > "geonature_${tag}.sql"

build: check_if_postgis_image_exists
	docker build --build-arg dump_filename="geonature_${tag}.sql" --build-arg pg_image_version=${pg_image_version} -t geonature-db-${tag}:${version} . 

dump_build: dump build

all: pull_geonature install_geonature update_geonature dump build




update_geonature:
	./GeoNature/backend/venv/bin/geonature db autoupgrade

status:
	./GeoNature/backend/venv/bin/geonature db status
