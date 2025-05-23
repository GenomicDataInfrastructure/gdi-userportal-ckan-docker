<!--
SPDX-FileCopyrightText: 2024 PNED G.I.E.

SPDX-License-Identifier: CC-BY-4.0
-->

[![REUSE status](https://api.reuse.software/badge/github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker)](https://api.reuse.software/info/github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker)
![example workflow](https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/actions/workflows/main.yml/badge.svg)
![example workflow](https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/actions/workflows/release.yml/badge.svg)
![example workflow](https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/actions/workflows/test.yml/badge.svg)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=GenomicDataInfrastructure_gdi-userportal-ckan-docker&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=GenomicDataInfrastructure_gdi-userportal-ckan-docker)
[![GitHub contributors](https://img.shields.io/github/contributors/GenomicDataInfrastructure/gdi-userportal-ckan-docker)](https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/graphs/contributors)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](code_of_conduct.md)

# CKAN for GDI - User Portal

## 1. Overview

This project has two purposes:
1. Prepare a docker image for CKAN, with all extensions and configurations needed to deploy the catalogue for the User Portal.
2. Setup a development environment for testing, fixing and enhancing our customised CKAN and its extensions.

The CKAN images used are from the official CKAN [ckan-docker](https://github.com/ckan/ckan-docker-base) repo.

The non-CKAN images are as follows:

* PostgreSQL: Official PostgreSQL image. Database files are stored in a named volume.
* Solr: CKAN's [pre-configured Solr image](https://github.com/ckan/ckan-solr). Index data is stored in a named volume.
* Redis: standard Redis image
* NGINX: latest stable nginx image that includes SSL and Non-SSL endpoints
* National Catalogue Mock: Python script to expose a synthetic RDF file, to test the Harvester.

CKAN and all the components are configured using environment variables that you can set in the `.env` file.

## 2. Before running locally

* Install docker with support to docker compose v2.
  * Ensure you have enough computer resources, if you are using `colima`: `colima start --arch aarch64 --vm-type=vz --mount-type=virtiofs --vz-rosetta --cpu 4 --memory 10`
* Copy `.env.example` to `.env`.
* Ensure git submodules are pulled correctly after clone CKAN-DOCKER `git submodule update --init`

## 3. Useful commands

### 3.1. Build and start dev environment
Use this mode if you are making code changes to CKAN and either creating new extensions or making code changes to existing extensions. This mode also uses the `.env` file for config options.

To develop local extensions use the `docker-compose.yml` file with help from the scripts under `bin`:

To build the images:
```bash
	bin/compose build
```
To install extensions from the `src` directory:
```bash
	bin/install_src
```
To start the containers:
```bash
	bin/compose up
```
Shut down and restart the whole ckan-dev container (use bin/compose up -d instead to reload new values from .env)
```bash
	bin/compose restart
```

### 3.2. Remove images and volumes
```bash
  bin/compose down -v
```

### 3.3. Logs
```bash
  bin/compose logs -f
```

### 3.4. Re-index SOLR
```bash
ckan -c ckan.ini search-index rebuild
```

## 4. Accessing the running instance

The ckan instance runs on port defined in CKAN_PORT_HOST (5500). Access it at http://localhost:5500.  
A sysadmin account is created by default with the following credentials (defined in .env):
- `CKAN_SYSADMIN_NAME=ckan_admin`
- `CKAN_SYSADMIN_PASSWORD=test1234`


## 5. installing new extensions

The current agreement is:
* Fork all the branches from the extension's repo into [GitHub GDI](https://github.com/GenomicDataInfrastructure).
* Create and push a new branch following this standard: `user-portal-{original branch name/tag name}`
  Reminder, prefer always to use a release/tag branch, over main/master branches, to avoid not tested changes.
* Add a git submodule: `git submodule add {git_ssh_url} src/ckanext-{extension}`.
* Add branch reference into `.gitmodules`, if not added.
* Configure the extension via environment variables or via a setup script. Setup scripts must be added into `ckan/docker-entrypoint.d/`.
* Ensure the extension is working as expected.
* Update `ckan/Dockerfile` to install the new extension via pip.

All Docker Compose commands in this README will use the V2 version of Compose ie: `docker compose`. The older version (V1) 
used the `docker-compose` command. Please see [Docker Compose](https://docs.docker.com/compose/compose-v2/) for
more information.

Copying and License
-------------------

This work is licensed under multiple licenses. Here is a brief summary as of January 2024:

- All original source code is licensed under [AGPL-3.0-only](./LICENSES/AGPL-3.0-only.txt), copyright (c) 2006-2024 Open Knowledge Foundation and contributors.
- All documentation is licensed under [CC-BY-4.0](./LICENSES/CC-BY-4.0.txt).
- github actions workflows are licensed under [Apache-2.0](./LICENSES/Apache-2.txt).
- For more accurate information, check the individual files.
