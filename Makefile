SHELL=/bin/bash -o pipefail
BUILD_PRINT = \e[1;34mSTEP:
END_BUILD_PRINT = \e[0m

CURRENT_UID := $(shell id -u)
export CURRENT_UID
# These are constants used for make targets so we can start prod and staging services on the same machine
ENV_FILE := .env

# include .env files if they exist
-include .env

PROJECT_PATH = $(shell pwd)
RML_MAPPER_PATH = ${PROJECT_PATH}/.rmlmapper/rmlmapper.jar
XML_PROCESSOR_PATH = ${PROJECT_PATH}/.saxon/saxon-he-10.6.jar
LOCAL_ID_MANAGER_API_HOST = localhost
LOCAL_ID_MANAGER_API_PORT = 8000

#-----------------------------------------------------------------------------
# Dev commands
#-----------------------------------------------------------------------------
setup: install install-rmlmapper init-saxon local-dotenv-file

install:
	@ echo -e "$(BUILD_PRINT)Installing user requirements$(END_BUILD_PRINT)"
	@ python -m pip install --upgrade pip
	@ python -m pip install --no-cache-dir --upgrade --force-reinstall -r requirements.txt

dev-dotenv-file: init-dotenv-file rml-mapper-path-add-dotenv-file saxon-path-add-dotenv-file dev-secrets-dotenv-file

local-dotenv-file: init-dotenv-file-local rml-mapper-path-add-dotenv-file saxon-path-add-dotenv-file local-secrets-dotenv-file

init-dotenv-file:
	@ echo VAULT_ADDR=${VAULT_ADDR} > $(ENV_FILE)
	@ echo VAULT_TOKEN=${VAULT_TOKEN} >> $(ENV_FILE)

init-dotenv-file-local:
	@ test -e $(ENV_FILE) || touch $(ENV_FILE)

rml-mapper-path-add-dotenv-file:
	@ echo -e "$(BUILD_PRINT)Add rml-mapper path to local .env file $(END_BUILD_PRINT)"
	@ sed -i '/^RML_MAPPER_PATH/d' $(ENV_FILE)
	@ echo RML_MAPPER_PATH=${RML_MAPPER_PATH} >> $(ENV_FILE)

dev-secrets-dotenv-file:
	@ vault kv get -format="json" ted-dev/ted-sws | jq -r ".data.data | keys[] as \$$k | \"\(\$$k)=\(.[\$$k])\"" >> $(ENV_FILE)

local-secrets-dotenv-file:
	@ echo -e "$(BUILD_PRINT)Add local secrets to local .env file $(END_BUILD_PRINT)"
	@ sed -i '/^ID_MANAGER_API_HOST/d' $(ENV_FILE)
	@ echo ID_MANAGER_API_HOST=${LOCAL_ID_MANAGER_API_HOST} >> $(ENV_FILE)
	@ sed -i '/^ID_MANAGER_API_PORT/d' $(ENV_FILE)
	@ echo ID_MANAGER_API_PORT=${LOCAL_ID_MANAGER_API_PORT} >> $(ENV_FILE)
	@ sed -i '/^AGRAPH_SUPER_PASSWORD/d' $(ENV_FILE)
	@ echo AGRAPH_SUPER_PASSWORD=${AGRAPH_SUPER_PASSWORD} >> $(ENV_FILE)
	@ sed -i '/^AGRAPH_SUPER_USER/d' $(ENV_FILE)
	@ echo AGRAPH_SUPER_USER=${AGRAPH_SUPER_USER} >> $(ENV_FILE)
	@ sed -i '/^ALLEGRO_HOST/d' $(ENV_FILE)
	@ echo ALLEGRO_HOST=${ALLEGRO_HOST} >> $(ENV_FILE)

install-rmlmapper:
	@ rm -rf ./.rmlmapper
	@ mkdir -p ./.rmlmapper
	@ wget -c https://github.com/meaningfy-ws/rmlmapper-java/releases/download/6.1.3a/rmlmapper-6.1.3a-r367-all.jar -O ./.rmlmapper/rmlmapper.jar

install-rmlmapper-with-cached-xmlresolver:
	@ rm -rf ./.rmlmapper
	@ mkdir -p ./.rmlmapper
	@ wget -c https://github.com/meaningfy-ws/rmlmapper-java/releases/download/6.1.3a/rmlmapper-6.1.3a-cache-r368-all.jar -O ./.rmlmapper/rmlmapper.jar

init-saxon:
	@ echo -e "$(BUILD_PRINT)Saxon folder initialization $(END_BUILD_PRINT)"
	@ wget -c https://downloads.sourceforge.net/project/saxon/Saxon-HE/10/Java/SaxonHE10-6J.zip -P .saxon/
	@ cd .saxon && unzip SaxonHE10-6J.zip

saxon-path-add-dotenv-file:
	@ echo -e "$(BUILD_PRINT)Add Saxon path to local .env file $(END_BUILD_PRINT)"
	@ sed -i '/^XML_PROCESSOR_PATH/d' $(ENV_FILE)
	@ echo XML_PROCESSOR_PATH=${XML_PROCESSOR_PATH} >> $(ENV_FILE)

clean:
	@ test -d .saxon && rm -rfv .saxon/SaxonHE10-6J.zip

clear-output:
	@ rm -rf mappings/$(id)/output/*
	@ rm -rf mappings/$(id)/validation/sparql/cm_assertions/*

install-dev: install
	@ echo -e "$(BUILD_PRINT)Installing dev requirements$(END_BUILD_PRINT)"
	@ python -m pip install --no-cache-dir --upgrade --force-reinstall -r requirements-dev.txt

test:
	@ mapping_suite_validator package_F03
	@ mapping_suite_validator package_F03_test
	@ mapping_suite_validator package_F06
	@ mapping_suite_validator package_F13
	@ mapping_suite_validator package_F20
	@ mapping_suite_validator package_F21
	@ mapping_suite_validator package_F22
	@ mapping_suite_validator package_F23
	@ mapping_suite_validator package_F25
	@ mapping_suite_validator package_F01
	@ mapping_suite_validator package_F02
	@ mapping_suite_validator package_F04
	@ mapping_suite_validator package_F05
	@ mapping_suite_validator package_F08
	@ mapping_suite_validator package_F12
	@ mapping_suite_validator package_F24


clear-xml-resolver-cache:
	@ echo -e "$(BUILD_PRINT)Clear XML resolver cache!$(END_BUILD_PRINT)"
	@ rm -r ~/.xmlresolver.org

