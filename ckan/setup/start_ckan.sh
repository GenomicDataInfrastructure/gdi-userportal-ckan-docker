#!/bin/bash

# SPDX-FileCopyrightText: 2006-2024 Open Knowledge Foundation and contributors
#
# SPDX-License-Identifier: AGPL-3.0-only

if [[ $CKAN__PLUGINS == *"datapusher"* ]]; then
    # Add ckan.datapusher.api_token to the CKAN config file (updated with corrected value later)
    echo "Setting a temporary value for ckan.datapusher.api_token"
    ckan config-tool $CKAN_INI ckan.datapusher.api_token=xxx
fi

# Set up the Secret key used by Beaker and Flask
# This can be overriden using a CKAN___BEAKER__SESSION__SECRET env var
if grep -qE "SECRET_KEY ?= ?$" ckan.ini
then
    echo "Setting SECRET_KEY in ini file"
    ckan config-tool $CKAN_INI "SECRET_KEY=$(python3 -c 'import secrets; print(secrets.token_urlsafe())')"
    ckan config-tool $CKAN_INI "WTF_CSRF_SECRET_KEY=$(python3 -c 'import secrets; print(secrets.token_urlsafe())')"
    JWT_SECRET=$(python3 -c 'import secrets; print("string:" + secrets.token_urlsafe())')
    ckan config-tool $CKAN_INI "api_token.jwt.encode.secret=${JWT_SECRET}"
    ckan config-tool $CKAN_INI "api_token.jwt.decode.secret=${JWT_SECRET}"
    ckan config-tool $CKAN_INI "ckan.harvest.s3_rdf.aws_access_key=${CKAN_HARVEST_S3_RDF_AWS_ACCESS_KEY}"
    ckan config-tool $CKAN_INI "ckan.harvest.s3_rdf.aws_secret_key=${CKAN_HARVEST_S3_RDF_AWS_SECRET_KEY}"
fi

if [[ -n "${CKANEXT_FAIRDATAPOINT_BIOPORTAL_API_KEY:-}" ]]
then
    echo "Adding bioportal_api_key to ini file."
    ckan config-tool $CKAN_INI "ckanext.fairdatapoint.bioportal_api_key=${CKANEXT_FAIRDATAPOINT_BIOPORTAL_API_KEY}"
fi

# Generate the dataset schema for the enabled metadata profiles (GDI_METADATA_PROFILES,
# GDI_METADATA_MAIN_PROFILE) and point CKAN at it. This must run before prerun.py: prerun loads
# CKAN, and with it the schema that scheming is configured with.
echo "[metadata-profiles] Generating the dataset schema"
if ! METADATA_PROFILE_CONFIG=$(PYTHONUSERBASE="${APP_DIR}/.local" python3 -m ckanext.gdi_userportal.profile_packs.generator --output-dir "${APP_DIR}/generated")
then
    echo "[metadata-profiles] failed...not starting CKAN."
    exit 1
fi
mapfile -t METADATA_PROFILE_OPTIONS <<< "$METADATA_PROFILE_CONFIG"
ckan config-tool $CKAN_INI -s app:main "${METADATA_PROFILE_OPTIONS[@]}"

# Sync the Solr core with the enabled profiles (see profile_packs/README.md, "Solr schema"): the core
# is created once from the Solr image, so a new profile field would otherwise not reach it. A failure
# is logged and never stops CKAN; search keeps working with the schema the core has.
echo "[solr-schema] Syncing the Solr schema"
PYTHONUSERBASE="${APP_DIR}/.local" python3 -m ckanext.gdi_userportal.profile_packs.solr_schema sync \
    --dataset-schema "${APP_DIR}/generated/dataset.yaml" \
    || echo "[solr-schema] could not sync the Solr schema, see above"

# Run the prerun script to init CKAN and create the default admin user.
# It runs as root, so point it at the ckan user's site-packages, where the image installs the extensions.
if ! PYTHONUSERBASE="${APP_DIR}/.local" python3 prerun.py
then
    echo "[prerun] failed...not starting CKAN."
    exit 1
fi

# Run any startup scripts provided by images extending this one
if [[ -d "/docker-entrypoint.d" ]]
then
    for f in /docker-entrypoint.d/*; do
        case "$f" in
            *.sh)     echo "$0: Running init file $f"; . "$f" ;;
            *.py)     echo "$0: Running init file $f"; python3 "$f"; echo ;;
            *)        echo "$0: Ignoring $f (not an sh or py file)" ;;
        esac
    done
fi

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
            --harakiri $UWSGI_HARAKIRI"

supervisord --configuration /etc/supervisord.d/ckan.conf
# Start uwsgi as ckan while keeping the container runtime root for cron.
if command -v runuser >/dev/null 2>&1; then
    runuser -u ckan -- sh -lc "uwsgi $UWSGI_OPTS"
else
    su -s /bin/sh ckan -c "uwsgi $UWSGI_OPTS"
fi
