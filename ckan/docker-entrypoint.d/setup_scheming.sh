#!/bin/bash

# SPDX-FileCopyrightText: 2024 PNED G.I.E.
#
# SPDX-License-Identifier: AGPL-3.0-only

# Update the config file with each extension config-options
echo "[ckanext-scheming] Setting up config-options"
ckan config-tool $CKAN_INI -s app:main \
    "scheming.dataset_schemas = ckanext.dcat.schemas:health_dcat_ap.yaml ckanext.gdi_userportal:scheming/schemas/gdi_userportal.yaml ckanext.dataset_series.schemas:dcat_ap_dataset_series.yaml" \
    "scheming.presets = ckanext.scheming:presets.json ckanext.dcat.schemas:presets.yaml ckanext.gdi_userportal:scheming/presets/gdi_presets.yaml" \
    "scheming.dataset_fallback = false" \
    "ckanext.dcat.rdf.profiles = euro_health_dcat_ap euro_dcat_ap_scheming fairdatapoint_dcat_ap" \
    "ckanext.dcat.compatibility_mode = false"


