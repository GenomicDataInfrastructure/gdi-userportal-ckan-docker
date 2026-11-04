#!/bin/bash

# SPDX-FileCopyrightText: 2026 Stichting Health-RI
#
# SPDX-License-Identifier: AGPL-3.0-only

# The webassets cache is written as root (this entrypoint chain) and read as the ckan user (the web
# server). prerun.py's chown does not cover it and is skipped once the sysadmin exists, so fix the
# ownership on every start: stale root-owned cache files cause PermissionError on asset lookup.
echo "[fix_webassets_permissions] Ensuring webassets cache is owned by ckan"
mkdir -p "$CKAN_STORAGE_PATH/webassets"
chown -R ckan:ckan-sys "$CKAN_STORAGE_PATH/webassets"
