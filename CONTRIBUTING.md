<!--
SPDX-FileCopyrightText: 2024 PNED G.I.E.

SPDX-License-Identifier: CC-BY-4.0
-->

# Contributing to CKAN for GDI - User Portal

Thanks for contributing. This repository builds the CKAN images for the GDI User Portal and the
development stack around them. The extension code lives in submodules under `src/`, so first decide
where a change belongs.

## Code of Conduct

This project follows the [Code of Conduct](CODE_OF_CONDUCT.md). Report unacceptable behaviour to the
maintainers through the [GenomicDataInfrastructure](https://github.com/GenomicDataInfrastructure)
organisation on GitHub.

## Where a change belongs

- **This repository**: Docker images, the compose stack, start scripts, entrypoint scripts and the
  environment contract in `.env.example`.
- **An extension** (`src/ckanext-*`): schemas, RDF mapping, harvesters, the Solr schema. Make the change
  and its pull request in the extension's repository, then update the submodule pointer here in a
  separate commit.

## Setting up

1. Install Docker with Compose v2.
2. Check out the submodules: `git submodule update --init`.
3. Copy `.env.example` to `.env` and replace every `changeme` value. Never commit `.env`.
4. Build and start the stack: `bin/compose build`, `bin/install_src`, `bin/compose up`.

The README describes the commands and the services in more detail.

## Running tests

- The profile pack tests run on the host, without CKAN. The command is in
  [docs/metadata-profiles.md](docs/metadata-profiles.md), under *Add a profile*.
- Do not run the extension test suites inside the `ckan-dev` container. The ckanext-dcat and
  ckanext-fairdatapoint suites reset its database. Database-backed tests need a database of their own.

## Reporting bugs and asking questions

Search the [existing issues](https://github.com/GenomicDataInfrastructure/gdi-userportal-ckan-docker/issues)
first. If you open a new one, include:

- the steps that reproduce the problem, and what you expected to happen;
- the relevant output of `bin/compose logs ckan-dev`;
- your operating system and Docker version, and the commit you ran.

Remove passwords and keys from `.env` before you paste any logs or configuration.

## Reporting security issues

Do not report vulnerabilities in a public issue. Use GitHub's private vulnerability reporting for this
repository if it is enabled. Otherwise contact the maintainers privately through the
GenomicDataInfrastructure organisation.

## Suggesting enhancements

Open an issue that describes the problem, the change you propose and who it would help. Keep to the
scope of the User Portal catalogue.

## Branches, commits and pull requests

- Branch names: `type/short-description`, for example `fix/prerun-logging`. Do not push to `main`.
- Commit messages use a semantic prefix: `feat:`, `fix:`, `docs:`, `refactor:`, `chore:` or `test:`.
  The subject is in the imperative mood and at most 72 characters. The body explains why, when the
  reason is not obvious. Do not add co-author or generated-by lines.
- A pull request describes what changed and why, and how you verified it, with the commands you ran
  and their results. Update the documentation in the same pull request as the code it describes.

## Documentation

- [README.md](README.md): setup and everyday commands.
- [docs/metadata-profiles.md](docs/metadata-profiles.md): choosing and operating metadata profiles.
- [ckan/docker-entrypoint.d/README.md](ckan/docker-entrypoint.d/README.md): adding startup scripts.

New files need SPDX headers. The repository is checked for REUSE compliance.

## Licensing

Code is licensed under AGPL-3.0-only and documentation under CC-BY-4.0. By contributing you confirm
that you have the right to submit the contribution under these licenses.
