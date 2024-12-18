SHELL := /bin/bash

# Git version
tag ?= 2.15.0

# Version that will be indicated in the generate docker Image
version ?= latest

# Local PostgreSQL configuration
user_pg ?= geonatadmin
password_pg ?= geonatadmin
pg_port ?= 5432
pg_database ?= geonature2db_dump

pg_image_version ?= 17-3.5-alpine
exit_status := $(shell ./docker_exists.sh $(pg_image_version))

# Module
monitoring_version ?= 1.0.0
export_version ?= 1.7.2
dashboard_version ?= 1.5.0


check_if_postgis_image_exists:
	if [ $(exit_status) -eq 0 ]; then echo "Image postgis/postgis:${pg_image_version} exists"; else echo "Image postgis/postgis:${pg_image_version} does not exist"; fi; 

generate_config:
	cat geonature_config.toml.template | sed "s/\$$user_pg/${user_pg}/g" | sed "s/\$$password_pg/${password_pg}/g" | sed "s/\$$pg_port/${pg_port}/g" | sed "s/\$$pg_database/${pg_database}/g" > geonature_config.toml
	cat settings.ini.template | sed "s/\$$user_pg/${user_pg}/g" | sed "s/\$$password_pg/${password_pg}/g" | sed "s/\$$pg_port/${pg_port}/g" | sed "s/\$$pg_database/${pg_database}/g" > settings.ini

pull_geonature: 

	if [ ! -d GeoNature ]; then git clone https://github.com/PnX-SI/GeoNature.git; fi
	cd GeoNature && git fetch origin
	cd GeoNature && git checkout ${tag}
	cd GeoNature && git submodule init && git submodule update

pull_modules: 
	
	if [ ! -d gn_module_monitoring ]; then git clone https://github.com/PnX-SI/gn_module_monitoring.git; fi
	if [ ! -d gn_module_export ]; then git clone https://github.com/PnX-SI/gn_module_export.git; fi
	if [ ! -d gn_module_dashboard ]; then git clone https://github.com/PnX-SI/gn_module_dashboard.git; fi
	cd gn_module_monitoring && git fetch origin && git checkout ${monitoring_version}
	cd gn_module_export && git fetch origin && git checkout ${export_version}
	cd gn_module_dashboard && git fetch origin && git checkout ${dashboard_version}

install_modules: pull_modules
	source ./GeoNature/backend/venv/bin/activate && geonature install-gn-module gn_module_monitoring --upgrade-db=true  --build=false
	source ./GeoNature/backend/venv/bin/activate && geonature install-gn-module gn_module_export --upgrade-db=true  --build=false
	source ./GeoNature/backend/venv/bin/activate && geonature install-gn-module gn_module_dashboard --upgrade-db=true  --build=false


install_geonature: pull_geonature generate_config

	cp settings.ini GeoNature/config/
	cp geonature_config.toml GeoNature/config/
	cd GeoNature && git fetch origin
	cd GeoNature && git checkout ${tag} && git submodule update
	cd GeoNature/install && ./01_install_backend.sh && ./03_create_db.sh && ./04_install_gn_modules.sh

install_geonature_with_modules: install_geonature install_modules

dump:
	pg_dump -U ${user_pg} -h localhost -p 5432 ${pg_database} > "geonature_${tag}.sql"

build: check_if_postgis_image_exists
	docker build --build-arg dump_filename="geonature_${tag}.sql" --build-arg pg_image_version=${pg_image_version} -t geonature-db-${tag}:${version} . 

dump_build: dump build

update_geonature:
	./GeoNature/backend/venv/bin/geonature db autoupgrade

status:
	./GeoNature/backend/venv/bin/geonature db status

all: pull_geonature install_geonature_with_modules update_geonature dump_build




