#!/bin/bash

# SPDX-FileCopyrightText: 2024 PNED G.I.E.
#
# SPDX-License-Identifier: AGPL-3.0-only

# Set the ckanext-scheming and ckanext-dcat options that do not depend on the metadata profiles.
# scheming.dataset_schemas, scheming.presets and ckanext.dcat.rdf.profiles are set earlier by
# the metadata profile generator (see start_ckan.sh), because prerun.py already needs them.
echo "[ckanext-scheming] Setting up config-options"
ckan config-tool $CKAN_INI -s app:main \
    "scheming.dataset_fallback = false" \
    "ckanext.dcat.compatibility_mode = false"
