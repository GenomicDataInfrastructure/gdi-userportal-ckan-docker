# SPDX-FileCopyrightText: 2006-2024 Open Knowledge Foundation and contributors
#
# SPDX-License-Identifier: AGPL-3.0-only

FROM docker.io/postgres:17-alpine

# Include extra setup scripts (eg datastore)
COPY --chown=postgres:postgres docker-entrypoint-initdb.d /docker-entrypoint-initdb.d
