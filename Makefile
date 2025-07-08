SHELL := /bin/bash

# Git version
tag ?= stock

# Version that will be indicated in the generate docker Image
version ?= 2.16.0

# Local PostgreSQL configuration
user_pg ?= geonatadmin
password_pg ?= geonatadmin
pg_port ?= 5432
pg_database ?= geonature2db

# Module
monitoring_version ?= 1.0.3
export_version ?= 1.8.0
dashboard_version ?= 1.6.0

dump_filename = geonature_2.15.0.bin

pull_modules: 
	if [ ! -d gn_module_monitoring ]; then git clone https://github.com/PnX-SI/gn_module_monitoring.git; fi
	if [ ! -d gn_module_export ]; then git clone https://github.com/PnX-SI/gn_module_export.git; fi
	if [ ! -d gn_module_dashboard ]; then git clone https://github.com/PnX-SI/gn_module_dashboard.git; fi
	cd gn_module_monitoring && git fetch origin && git checkout ${monitoring_version}
	cd gn_module_export && git fetch origin && git checkout ${export_version}
	cd gn_module_dashboard && git fetch origin && git checkout ${dashboard_version}

build: pull_modules
	docker build \
	--build-arg pg_user=${user_pg} \
	--build-arg pg_password=${password_pg} \
	--build-arg pg_database=geonature2db \
	--build-arg GEONATURE_VERSION=${version} \
	-t geonature-db-${tag}:${version} . 

build_from_dump: 
	docker build \
	-f Dockerfile.fromdump \
	--build-arg dump_filename=${dump_filename} \
	-t geonature-db-dump:$(basename ${dump_filename}) .

run:
	docker run -d \
	--name geonature-db-${tag} \
	--rm \
	-p ${pg_port}:5432 \
	geonature-db-${tag}:${version}

run_from_dump:
	docker run -d \
	--name geonature-db-dump \
	--rm \
	-p ${pg_port}:5432 \
	geonature-db-dump:$(basename ${dump_filename})






