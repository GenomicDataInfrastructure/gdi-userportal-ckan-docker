#!/bin/bash

# SPDX-FileCopyrightText: 2006-2024 Open Knowledge Foundation and contributors
#
# SPDX-License-Identifier: AGPL-3.0-only

# The production start. The steps it shares with the development start are in start_ckan_common.sh.
# shellcheck source=ckan/setup/start_ckan_common.sh
. "${APP_DIR}/start_ckan_common.sh"

set_secret_keys
set_extension_keys
generate_metadata_profile_schema
sync_solr_schema
run_prerun
run_entrypoint_scripts

# --need-app: a worker that cannot load CKAN (the database is down) makes uwsgi exit, so the container
# restarts and prerun.py waits for the database, instead of uwsgi answering 500 until someone
# restarts it (see README 3.6).
UWSGI_OPTS="--socket /tmp/uwsgi.sock \
            --wsgi-file /srv/app/wsgi.py \
            --module wsgi:application \
            --http [::]:5000 \
            --master --enable-threads \
            --lazy-apps --need-app \
            -p 2 -L -b 32768 --vacuum \
            ${UWSGI_HARAKIRI:+--harakiri $UWSGI_HARAKIRI}"

supervisord --configuration /etc/supervisord.d/ckan.conf
# Start uwsgi as ckan while keeping the container runtime root for cron.
if command -v runuser >/dev/null 2>&1; then
    runuser -u ckan -- sh -lc "uwsgi $UWSGI_OPTS"
else
    su -s /bin/sh ckan -c "uwsgi $UWSGI_OPTS"
fi
