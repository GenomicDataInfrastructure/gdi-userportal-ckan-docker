#!/bin/bash

# SPDX-FileCopyrightText: 2024 PNED G.I.E.
#
# SPDX-License-Identifier: AGPL-3.0-only

# Point ckanext-harvest at the Redis message queue configured in .env.
echo "[ckanext-harvest] Setting up config-options"
ckan config-tool $CKAN_INI -s app:main \
    "ckan.harvest.timeout = 60" \
    "ckan.harvest.mq.type = redis" \
    "ckan.harvest.mq.hostname = $CKAN__HARVEST__MQ__HOSTNAME" \
    "ckan.harvest.mq.port = $CKAN__HARVEST__MQ__PORT" \
    "ckan.harvest.mq.password = $CKAN__HARVEST__MQ__PASSWORD" \
    "ckan.harvest.mq.redis_db = $CKAN__HARVEST__MQ__REDIS_DB"
