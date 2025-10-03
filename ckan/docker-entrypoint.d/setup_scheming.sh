#!/bin/bash

# SPDX-FileCopyrightText: 2024 PNED G.I.E.
#
# SPDX-License-Identifier: AGPL-3.0-only

# Update the config file with each extension config-options
echo "[ckanext-scheming] Setting up config-options"
ckan config-tool $CKAN_INI -s app:main \
    "scheming.dataset_schemas = ckanext.gdi_userportal:scheming/schemas/dataset_multilingual.yaml ckanext.gdi_userportal:scheming/schemas/dataset_series_multilingual.yaml" \
    "scheming.presets = ckanext.scheming:presets.json ckanext.dcat.schemas:presets.yaml ckanext.fluent:presets.json ckanext.gdi_userportal:scheming/presets/gdi_presets.yaml ckanext.dataset_series.schemas:presets.yaml" \
    "scheming.dataset_fallback = false" \
    "ckanext.dcat.rdf.profiles = fairdatapoint_dcat_ap" \
    "ckanext.dcat.compatibility_mode = false"
