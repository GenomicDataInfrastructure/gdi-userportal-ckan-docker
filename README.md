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
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](CODE_OF_CONDUCT.md)

# CKAN for GDI - User Portal

## 1. Overview

This project has two purposes:
1. Prepare a docker image for CKAN, with all extensions and configurations needed to deploy the catalogue for the User Portal.
2. Setup a development environment for testing, fixing and enhancing our customised CKAN and its extensions.

The CKAN images used are from the official CKAN [ckan-docker](https://github.com/ckan/ckan-docker-base) repo.

The services of the development stack (`docker-compose.yml`) are:

* `ckan-dev`: CKAN built from `ckan/Dockerfile.dev`, with the extensions of `src/` mounted in.
* `db`: PostgreSQL. Database files are stored in a named volume.
* `solr`: CKAN's [pre-configured Solr image](https://github.com/ckan/ckan-solr), with the schema of `ckanext-gdi-userportal`. Index data is stored in a named volume.
* `redis`: standard Redis image, used by the harvester.

CKAN and all the components are configured using environment variables. `.env` holds the development
defaults and is part of the repository, because compose reads it for every service. `.env.example`
lists every variable with its default, including the optional ones that `.env` leaves out.

## 2. Before running locally

* Install docker with support to docker compose v2.
  * Ensure you have enough computer resources, if you are using `colima`: `colima start --arch aarch64 --vm-type=vz --mount-type=virtiofs --vz-rosetta --cpu 4 --memory 10`
* The settings are in `.env`, which comes with the clone. Do not commit real credentials to it: a deployment sets the variables in the environment of the container instead.
* Ensure git submodules are pulled correctly after clone gdi-userportal-ckan-docker: `git submodule update --init`
* `ckan-dev` is built for `linux/amd64` in `docker-compose.yml`, so it also runs on Apple Silicon.

## 3. Useful commands

The scripts under `bin/` are thin wrappers around `docker compose -f docker-compose.yml`. Run them from
the repository root.

### 3.1. Build and start the dev environment

Use this mode if you are changing CKAN or its extensions. It reads the `.env` file for config options.

```bash
bin/compose build        # build the images
bin/install_src          # install the extensions of src/ in a one-off ckan-dev container (see section 5)
bin/compose up           # start the containers
bin/compose up -d --force-recreate ckan-dev   # re-read a changed .env
bin/compose restart      # restart the ckan-dev container only (a plain restart does not re-read .env)
```

### 3.2. Remove images and volumes

```bash
bin/compose down -v
```

This also deletes the dev database and the Solr index. Take a backup first if you need the data.

### 3.3. Logs

```bash
bin/compose logs -f
```

### 3.4. Run CKAN commands and re-index Solr

`bin/ckan` runs the `ckan` CLI inside the `ckan-dev` container:

```bash
bin/ckan search-index rebuild
```

### 3.5. Metadata profiles

One deployment can load the existing metadata model (`gdi_current`), HealthDCAT-AP R8
(`healthdcat_r8`) or both, chosen at container start with `GDI_METADATA_PROFILES`. Select, add,
remove and roll back a profile: [docs/metadata-profiles.md](docs/metadata-profiles.md). Already
running the stack: [Updating an existing deployment](docs/metadata-profiles.md#updating-an-existing-deployment).

### 3.6. Database outage

Stopping the database must not take CKAN down for good:

```bash
bin/compose stop db     # API calls that need the database answer 500
bin/compose start db    # the same calls work again, without restarting CKAN
```

The dev server recovers on its own. The production image runs uwsgi with `--need-app`: a worker that
cannot load CKAN (a restart while the database is down) makes uwsgi exit, the platform restarts the
container, and `prerun.py` waits for the database (exiting non-zero when it gives up), until the
database is back.

## 4. Accessing the running instance

CKAN listens on the host port `CKAN_PORT_HOST` (default 5500): http://localhost:5500.

A sysadmin account is created at the first start from `CKAN_SYSADMIN_NAME`, `CKAN_SYSADMIN_PASSWORD`
and `CKAN_SYSADMIN_EMAIL` in `.env`.

## 5. Developing an extension in `src/`

The `src/` directory is mounted into the `ckan-dev` container at `/srv/app/src_extensions`. At every
container start, `ckan/docker-entrypoint.d/00_install_local_extensions.sh` installs each
`src/ckanext-*` directory in editable mode, so an edit in `src/` is live without a rebuild. Its
requirements are installed with the security pins as constraints. After adding an extension or changing
its requirements, run `bin/compose restart`: the start runs the install again.

`bin/install_src` runs the same install script in a one-off container, as root and without starting
CKAN. Use it to install after a change without restarting the container.

PostgreSQL is published on `127.0.0.1:5432` for local tools only (for example `psql`). CKAN reaches the
database over the compose network as `db`, so nothing else needs the host port.

## 6. Adding an extension

The current agreement is:
* Fork all the branches from the extension's repo into [GitHub GDI](https://github.com/GenomicDataInfrastructure).
* Create and push a new branch following this standard: `user-portal-{original branch name/tag name}`.
  Prefer a release/tag branch over main/master, to avoid untested changes.
* Add a git submodule: `git submodule add {git_ssh_url} src/ckanext-{extension}`.
* Add the branch reference to `.gitmodules`, if it is not there yet.
* Configure the extension via environment variables or via a setup script. Setup scripts go into `ckan/docker-entrypoint.d/`; see the README there for the run order.
* Ensure the extension works in the dev stack (section 5).
* Add it to the production image: install it with pip from its git tag in `ckan/Dockerfile`.

All Docker Compose commands in this README use Compose V2 (`docker compose`). The older V1 tool (`docker-compose`) is not supported.
See [Docker Compose](https://docs.docker.com/compose/compose-v2/) for more information.

## Copyright and license

This work is licensed under multiple licenses:

- All original source code is licensed under [AGPL-3.0-only](./LICENSES/AGPL-3.0-only.txt), copyright (c) 2006-2024 Open Knowledge Foundation and contributors.
- All documentation is licensed under [CC-BY-4.0](./LICENSES/CC-BY-4.0.txt).
- GitHub Actions workflows are licensed under [Apache-2.0](./LICENSES/Apache-2.0.txt).
- For more accurate information, check the individual files.
