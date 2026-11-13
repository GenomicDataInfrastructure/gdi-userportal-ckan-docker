#!/bin/sh

# SPDX-FileCopyrightText: 2024 PNED G.I.E.
#
# SPDX-License-Identifier: AGPL-3.0-only

# Intentionally does nothing. The debug flag and the ckanext logger level are not set from
# CKAN___DEBUG and CKAN___LOGGER_CKANEXT__LEVEL here. To set them, uncomment these lines:
#ckan config-tool $CKAN_INI  -s DEFAULT "debug = $CKAN___DEBUG"
#ckan config-tool $CKAN_INI  -s logger_ckanext "level = $CKAN___LOGGER_CKANEXT__LEVEL"
