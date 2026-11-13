# shellcheck shell=bash

# SPDX-FileCopyrightText: 2006-2024 Open Knowledge Foundation and contributors
#
# SPDX-License-Identifier: AGPL-3.0-only

# The steps of the container start that the production script (start_ckan.sh) and the development
# script (start_ckan_development.sh) share. Each script sources this file and calls the steps in its
# own order, then starts the web server its own way. A step that must stop the start exits the script.

# Generate the secret keys while the ini still has the empty SECRET_KEY placeholder.
set_secret_keys() {
    if grep -qE "SECRET_KEY ?= ?$" "$CKAN_INI"
    then
        local jwt_secret
        echo "Setting SECRET_KEY in ini file"
        ckan config-tool "$CKAN_INI" "SECRET_KEY=$(python3 -c 'import secrets; print(secrets.token_urlsafe())')"
        ckan config-tool "$CKAN_INI" "WTF_CSRF_SECRET_KEY=$(python3 -c 'import secrets; print(secrets.token_urlsafe())')"
        jwt_secret=$(python3 -c 'import secrets; print("string:" + secrets.token_urlsafe())')
        ckan config-tool "$CKAN_INI" "api_token.jwt.encode.secret=${jwt_secret}"
        ckan config-tool "$CKAN_INI" "api_token.jwt.decode.secret=${jwt_secret}"
    fi
}

# Keys of the extensions that come from the environment. Written on every start, so the ini follows
# the environment after a restart.
set_extension_keys() {
    ckan config-tool "$CKAN_INI" "ckan.harvest.s3_rdf.aws_access_key=${CKAN_HARVEST_S3_RDF_AWS_ACCESS_KEY}"
    ckan config-tool "$CKAN_INI" "ckan.harvest.s3_rdf.aws_secret_key=${CKAN_HARVEST_S3_RDF_AWS_SECRET_KEY}"

    if [[ -n "${CKANEXT_FAIRDATAPOINT_BIOPORTAL_API_KEY:-}" ]]
    then
        echo "Adding bioportal_api_key to ini file."
        ckan config-tool "$CKAN_INI" "ckanext.fairdatapoint.bioportal_api_key=${CKANEXT_FAIRDATAPOINT_BIOPORTAL_API_KEY}"
    fi
}

# Generate the dataset schema for the enabled metadata profiles (GDI_METADATA_PROFILES,
# GDI_METADATA_MAIN_PROFILE) and point CKAN at it. This must run before prerun.py: prerun loads
# CKAN, and with it the schema that scheming is configured with.
generate_metadata_profile_schema() {
    local config options
    echo "[metadata-profiles] Generating the dataset schema"
    if ! config=$(PYTHONUSERBASE="${APP_DIR}/.local" python3 -m ckanext.gdi_userportal.profile_packs.generator --output-dir "${APP_DIR}/generated")
    then
        echo "[metadata-profiles] failed...not starting CKAN."
        exit 1
    fi
    mapfile -t options <<< "$config"
    ckan config-tool "$CKAN_INI" -s app:main "${options[@]}"
}

# Sync the Solr core with the enabled profiles (see profile_packs/README.md, "Solr schema"): the core
# is created once from the Solr image, so a new profile field would otherwise not reach it. A failure
# is logged and never stops CKAN; search keeps working with the schema the core has. It reads every
# schema of scheming.dataset_schemas (CKAN_INI) and removes the fields no schema describes any more.
sync_solr_schema() {
    echo "[solr-schema] Syncing the Solr schema"
    PYTHONUSERBASE="${APP_DIR}/.local" python3 -m ckanext.gdi_userportal.profile_packs.solr_schema sync \
        --ckan-ini "$CKAN_INI" \
        || echo "[solr-schema] could not sync the Solr schema, see above"
}

# Run the prerun script to init CKAN and create the default admin user.
# It runs as root, so point it at the ckan user's site-packages, where the image installs the extensions.
run_prerun() {
    if ! PYTHONUSERBASE="${APP_DIR}/.local" python3 prerun.py
    then
        echo "[prerun] failed...not starting CKAN."
        exit 1
    fi
}

# Run any startup scripts provided by images extending this one. The names given as arguments
# (file names, not paths) are skipped: a script that this start already ran.
run_entrypoint_scripts() {
    local f skipped
    if [[ -d "/docker-entrypoint.d" ]]
    then
        for f in /docker-entrypoint.d/*; do
            for skipped in "$@"; do
                if [[ "$(basename "$f")" == "$skipped" ]]
                then
                    echo "$0: Skipping $f (already ran earlier)"
                    continue 2
                fi
            done
            case "$f" in
                *.sh)     echo "$0: Running init file $f"; . "$f" ;;
                *.py)     echo "$0: Running init file $f"; python3 "$f"; echo ;;
                *)        echo "$0: Ignoring $f (not an sh or py file)" ;;
            esac
        done
    fi
}
