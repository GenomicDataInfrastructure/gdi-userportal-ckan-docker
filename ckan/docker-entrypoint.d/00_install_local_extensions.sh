#!/bin/bash

# SPDX-FileCopyrightText: 2024 PNED G.I.E.
#
# SPDX-License-Identifier: AGPL-3.0-only

# Install the extensions of the src_extensions volume mount (the development stack mounts ./src there).
#
# Run as a script it returns non-zero when an install or the import check fails. The production image
# has no src_extensions, and its start script sources this file, so everything is a function that
# returns instead of exiting.

install_local_extensions() {
    local ext_dir="/srv/app/src_extensions"
    local pins="${APP_DIR}/requirements-pins.txt"
    local constraints ext module failed=0

    if ! compgen -G "${ext_dir}/ckanext-*" > /dev/null; then
        echo "[local-extensions] No extensions in ${ext_dir}, nothing to install"
        return 0
    fi
    echo "[local-extensions] Installing local extensions from ${ext_dir}"

    # The security pins constrain every install, so an extension cannot downgrade a pinned package.
    # pip turns on hash checking for every package when a constraints file has hashes, so the
    # constraints are the pins without their hashes (Dockerfile.dev derives the same file).
    constraints="$(mktemp)"
    if ! sed -E '/^[[:space:]]*(#|--hash)/d; s/[[:space:]\\]+$//' "$pins" > "$constraints" || [ ! -s "$constraints" ]; then
        echo "[local-extensions] ERROR: cannot read the security pins from ${pins}"
        rm -f "$constraints"
        return 1
    fi

    for ext in "${ext_dir}"/ckanext-*; do
        [ -d "$ext" ] || continue
        echo "[local-extensions] Installing $ext"
        if [ -f "$ext/requirements.txt" ]; then
            echo "[local-extensions] Installing requirements from $ext/requirements.txt"
            pip install -c "$constraints" -r "$ext/requirements.txt" || failed=1
        fi
        pip install -c "$constraints" -e "$ext" || failed=1
    done
    rm -f "$constraints"

    # The hashed install of the pins, after every extension requirement, as in the Dockerfiles. The
    # site_packages volume keeps the packages of its first run, so the pins of the image never reach
    # a volume that is older than them: only this install brings them there.
    echo "[local-extensions] Installing the security pins"
    pip install --only-binary :all: --require-hashes -r "$pins" || failed=1

    # The extensions are installed editable, so a change in src/ is live without another install.
    # Say where each one is imported from: a copy left in site-packages by an older install would shadow it.
    for ext in "${ext_dir}"/ckanext-*; do
        [ -d "$ext" ] || continue
        module="ckanext.$(basename "$ext" | sed -e 's/^ckanext-//' -e 's/-/_/g')"
        if ! python3 -c 'import importlib, sys; path = list(importlib.import_module(sys.argv[1]).__path__)[0]; print("[local-extensions] " + sys.argv[1] + " is imported from " + path); sys.exit(0 if path.startswith(sys.argv[2]) else 1)' "$module" "$ext"; then
            echo "[local-extensions] ERROR: $module is not imported from $ext (or cannot be imported)"
            failed=1
        fi
    done

    if [ "$failed" -ne 0 ]; then
        return 1
    fi
    echo "[local-extensions] Done installing local extensions"
}

install_local_extensions
