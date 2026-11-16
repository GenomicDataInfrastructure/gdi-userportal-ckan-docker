#!/bin/bash

# SPDX-FileCopyrightText: 2006-2024 Open Knowledge Foundation and contributors
#
# SPDX-License-Identifier: AGPL-3.0-only

# The development start. The steps it shares with the production start are in start_ckan_common.sh.
# shellcheck source=ckan/setup/start_ckan_common.sh
. "${APP_DIR}/start_ckan_common.sh"

# The development image always runs with debug on, whatever CKAN___DEBUG says.
echo "Enabling debug mode"
ckan config-tool "$CKAN_INI" -s DEFAULT "debug = true"

set_secret_keys
set_extension_keys

# Update the plugins setting in the ini file with the values defined in the env var
echo "Loading the following plugins: $CKAN__PLUGINS"
ckan config-tool "$CKAN_INI" "ckan.plugins = $CKAN__PLUGINS"

# Install the extensions of src/ early, so CKAN CLI commands that load plugins
# (db init/upgrade, custom CLI, etc.) don't randomly fail on fresh volumes.
LOCAL_EXTENSIONS_SCRIPT="00_install_local_extensions.sh"
if [[ -f "/docker-entrypoint.d/${LOCAL_EXTENSIONS_SCRIPT}" ]]
then
    echo "Installing local extension requirements (before prerun/db init)..."
    if ! /bin/bash "/docker-entrypoint.d/${LOCAL_EXTENSIONS_SCRIPT}"
    then
        echo "[local-extensions] failed...not starting CKAN."
        exit 1
    fi
fi

generate_metadata_profile_schema
sync_solr_schema
run_prerun
run_entrypoint_scripts "$LOCAL_EXTENSIONS_SCRIPT"

CKAN_RUN="/usr/local/bin/ckan -c $CKAN_INI run -H 0.0.0.0"
CKAN_OPTIONS=""
if [ "$USE_DEBUGPY_FOR_DEV" = true ] ; then
    CKAN_RUN="/usr/local/bin/python -m debugpy --listen 0.0.0.0:5678 $CKAN_RUN"
    CKAN_OPTIONS="$CKAN_OPTIONS --disable-reloader"
fi

if [ "$USE_HTTPS_FOR_DEV" = true ] ; then
    CKAN_OPTIONS="$CKAN_OPTIONS -C unsafe.cert -K unsafe.key"
fi

supervisord --configuration /etc/supervisord.d/ckan.conf

# Start the development server as the ckan user with automatic reload
while true; do
    if command -v runuser >/dev/null 2>&1; then
        runuser -u ckan -- sh -lc "$CKAN_RUN $CKAN_OPTIONS"
    else
        su -s /bin/sh ckan -c "$CKAN_RUN $CKAN_OPTIONS"
    fi
    echo Exit with status $?. Restarting.
    sleep 2
done
