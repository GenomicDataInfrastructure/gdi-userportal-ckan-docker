#!/bin/bash
# SPDX-FileCopyrightText: 2024 Stichting Health-RI
#
# SPDX-License-Identifier: Apache-2.0

# Run term translation migrations on startup
# This ensures all required translations are present in the database

set -e

echo "=== Running term translation migrations ==="

# Wait for database to be ready (handled by previous scripts, but just in case)
if [ -z "$CKAN_SQLALCHEMY_URL" ]; then
    echo "Warning: CKAN_SQLALCHEMY_URL not set, skipping migrations"
    exit 0
fi

# Run migrations using the CKAN CLI
# The --config flag ensures we use the correct CKAN config
if command -v ckan &> /dev/null; then
    echo "Running: ckan gdi-userportal translations migrate"
    ckan -c /srv/app/ckan.ini gdi-userportal translations migrate || {
        echo "Warning: Term translation migrations failed, but continuing startup"
        echo "You can run migrations manually with: ckan gdi-userportal translations migrate"
    }
    echo "=== Term translation migrations complete ==="
else
    echo "Warning: CKAN CLI not available, skipping term translation migrations"
    echo "Run manually after startup: ckan gdi-userportal translations migrate"
fi
