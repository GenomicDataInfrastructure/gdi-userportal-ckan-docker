#!/bin/bash

# SPDX-FileCopyrightText: 2024 PNED G.I.E.
#
# SPDX-License-Identifier: AGPL-3.0-only

# Install local extensions from src_extensions volume mount
echo "[local-extensions] Installing local extensions from /srv/app/src_extensions"
for ext in /srv/app/src_extensions/ckanext-*; do
    if [ -d "$ext" ]; then
        echo "[local-extensions] Installing $ext"
        # Install requirements if they exist
        if [ -f "$ext/requirements.txt" ]; then
            echo "[local-extensions] Installing requirements from $ext/requirements.txt"
            pip install -r "$ext/requirements.txt"
        fi
        pip install -e "$ext"
    fi
done
# The extensions of src/ are installed editable, so a change in src/ is live without another install.
# Say where each one is imported from: a copy left in site-packages by an older install would shadow it.
for ext in /srv/app/src_extensions/ckanext-*; do
    if [ -d "$ext" ]; then
        module="ckanext.$(basename "$ext" | sed -e 's/^ckanext-//' -e 's/-/_/g')"
        if ! python3 -c 'import importlib, sys; path = list(importlib.import_module(sys.argv[1]).__path__)[0]; print("[local-extensions] " + sys.argv[1] + " is imported from " + path); sys.exit(0 if path.startswith(sys.argv[2]) else 1)' "$module" "$ext"; then
            echo "[local-extensions] ERROR: $module is not imported from $ext (the editable install of src/ is shadowed)"
        fi
    fi
done
echo "[local-extensions] Done installing local extensions"

