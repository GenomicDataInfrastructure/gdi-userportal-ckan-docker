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
echo "[local-extensions] Done installing local extensions"

