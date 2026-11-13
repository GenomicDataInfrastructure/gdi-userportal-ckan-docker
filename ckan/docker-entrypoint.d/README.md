<!--
SPDX-FileCopyrightText: 2006-2024 Open Knowledge Foundation and contributors

SPDX-License-Identifier: AGPL-3.0-only
-->

Use scripts in this folder to run extra initialization steps in the CKAN images.

- Each file with a `.sh` or `.py` extension runs once per container start, just after `prerun.py`
  and before the web server and supervisor processes start. Other files are ignored.
- Files run in the order of the shell glob, which is alphabetical by file name. Prefix a name with a
  number to control the order.
- `.sh` files are sourced into the start script, so `exit` in one of them stops the container start.
- The scripts run as root. The existing scripts change the CKAN ini with `ckan config-tool`.
- The development start script skips `00_install_local_extensions.sh`, because it already ran before
  `prerun.py`.
