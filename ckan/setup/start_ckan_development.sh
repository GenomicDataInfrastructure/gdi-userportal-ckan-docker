#!/bin/bash

# Set debug to true
echo "Enabling debug mode"
ckan config-tool $CKAN_INI -s DEFAULT "debug = true"

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
fi

# Update the plugins setting in the ini file with the values defined in the env var
echo "Loading the following plugins: $CKAN__PLUGINS"
ckan config-tool $CKAN_INI "ckan.plugins = $CKAN__PLUGINS"

# Run the prerun script to init CKAN and create the default admin user
python3 prerun.py

# Run any startup scripts provided by images extending this one
if [[ -d "/docker-entrypoint.d" ]]
then
    for f in /docker-entrypoint.d/*; do
        case "$f" in
            *.sh)     echo "$0: Running init file $f"; . "$f" ;;
            *.py)     echo "$0: Running init file $f"; python3 "$f"; echo ;;
            *)        echo "$0: Ignoring $f (not an sh or py file)" ;;
        esac
        echo
    done
fi

CKAN_RUN="/usr/local/bin/ckan -c $CKAN_INI run -H 0.0.0.0"
CKAN_OPTIONS=""
if [ "$USE_DEBUGPY_FOR_DEV" = true ] ; then
    CKAN_RUN="/usr/local/bin/python -m debugpy --listen 0.0.0.0:5678 $CKAN_RUN"
    CKAN_OPTIONS="$CKAN_OPTIONS --disable-reloader"
fi

if [ "$USE_HTTPS_FOR_DEV" = true ] ; then
    CKAN_OPTIONS="$CKAN_OPTIONS -C unsafe.cert -K unsafe.key"
fi

# Start the development server as the ckan user with automatic reload
while true; do
    supervisord --configuration /etc/supervisord.d/ckan.conf & 
    $CKAN_RUN $CKAN_OPTIONS
    echo Exit with status $?. Restarting.
    sleep 2
done