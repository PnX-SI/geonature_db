branch ?= 2.15.0
version ?= latest

pull_geonature:
	if [ ! -d GeoNature ];then git clone https://github.com/PnX-SI/GeoNature.git; fi
	cd GeoNature && git submodule init && git submodule update

install_geonature:
	cp settings.ini GeoNature/config/
	cp geonature_config.toml GeoNature/config/
	cd GeoNature && git fetch origin
	cd GeoNature && git checkout ${branch} && git submodule update
	cd GeoNature/install && ./01_install_backend.sh && ./03_create_db.sh && ./04_install_gn_modules.sh
	
update_geonature:
	./GeoNature/backend/venv/bin/geonature db autoupgrade

status:
	./GeoNature/backend/venv/bin/geonature db status

dump:
	pg_dump -U geonatadmin -h localhost -p 5432 geonature2db > "geonature_${branch}.sql"

build:
	docker build --build-arg dump_filename="geonature_${branch}.sql" -t geonature-db-${branch}:${version} . 

dump_build: dump build

