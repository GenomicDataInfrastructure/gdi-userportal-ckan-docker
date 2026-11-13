# SPDX-FileCopyrightText: 2006-2024 Open Knowledge Foundation and contributors
# SPDX-FileContributor: PNED G.I.E.
# SPDX-FileContributor: Stichting Health-RI
#
# SPDX-License-Identifier: AGPL-3.0-only

FROM ckan/ckan-base:2.11.5

USER root
RUN chown -R ckan:ckan-sys ${APP_DIR} /usr/local
USER ckan

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_ROOT_USER_ACTION=ignore \
    PIP_SRC=${APP_DIR}/src

# Security pins (certifi, PyJWT and others; see requirements-pins.txt for the CVEs).
# pip turns on hash checking for every package as soon as a constraints file has hashes, so the
# plugin installs below are constrained by the same versions without their hashes. The hashed
# install after them checks the files themselves.
COPY --chown=ckan-sys:ckan-sys requirements-pins.txt ${APP_DIR}/requirements-pins.txt

RUN set -eux; \
    sed -E '/^[[:space:]]*(#|--hash)/d; s/[[:space:]\\]+$//' "${APP_DIR}/requirements-pins.txt" > "${APP_DIR}/requirements-constraints.txt"; \
    python -m pip install --upgrade --no-cache-dir -c "${APP_DIR}/requirements-constraints.txt" pip "setuptools<82,>=44.1.0" wheel; \
    python -m pip install --no-cache-dir -c "${APP_DIR}/requirements-constraints.txt" \
        -e git+https://github.com/GenomicDataInfrastructure/gdi-userportal-ckanext-gdi-userportal.git@v1.14.3#egg=ckanext-gdi-userportal \
        -e git+https://github.com/GenomicDataInfrastructure/gdi-userportal-ckanext-dcat.git@v2.5.2#egg=ckanext-dcat \
        -e git+https://github.com/ckan/ckanext-dataset-series.git@v0.1.1#egg=ckanext-dataset-series \
        -e git+https://github.com/ckan/ckanext-harvest.git@v1.6.2#egg=ckanext-harvest \
        'ckanext-scheming[requirements] @ git+https://github.com/ckan/ckanext-scheming.git@ea79dc58bf1b0019e4336c5d2c2925aa9d7f39ed' \
        -e git+https://github.com/GenomicDataInfrastructure/gdi-userportal-ckanext-fairdatapoint.git@v1.7.4#egg=ckanext-fairdatapoint \
        -e git+https://github.com/ckan/ckanext-fluent.git@eb5581ac952cd1d0d3ceac78b43adb97e7068895#egg=ckanext-fluent; \
    for requirement in \
        ckanext-gdi-userportal \
        ckanext-dcat \
        ckanext-dataset-series \
        ckanext-harvest \
        ckanext-fairdatapoint \
        ckanext-fluent \
    ; do \
        req_file="${APP_DIR}/src/${requirement}/requirements.txt"; \
        if [ -f "${req_file}" ]; then \
            python -m pip install --no-cache-dir -c "${APP_DIR}/requirements-constraints.txt" -r "${req_file}"; \
        fi; \
    done; \
    python -m pip install --no-cache-dir -c "${APP_DIR}/requirements-constraints.txt" \
        pytest-ckan \
        'factory-boy>=2'; \
    python -m pip check

# The hashed install of the pins, after every plugin requirements file.
RUN set -eux; \
    python -m pip install --no-cache-dir --only-binary :all: --require-hashes -r "${APP_DIR}/requirements-pins.txt"; \
    python -m pip check

USER root

# The base image's system-wide certifi is used by anything that runs as root (prerun.py, entrypoint scripts).
RUN set -eux; \
    python -m pip install --no-cache-dir --only-binary :all: --require-hashes --upgrade -r "${APP_DIR}/requirements-pins.txt"; \
    python -m pip check

### Install cron and supervisor for the harvester.
# Upgrade the base image's Debian packages first: ckan-base lags behind Debian security updates.
# Kernel headers are useless in a container and their fixes ship as new packages that upgrade skips, so remove them.
RUN apt-get update && apt-get upgrade -y \
    && apt-get purge -y --auto-remove linux-headers-amd64 \
    && apt-get install -y --no-install-recommends \
    cron \
    supervisor \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/log/ckan/std /var/log/supervisor /etc/supervisor/conf.d \
    && chown -R ckan:ckan-sys /var/log/ckan /var/log/supervisor /etc/supervisor/conf.d

# Config cron job for harvesting
COPY config/supervisord.conf /etc/supervisord.d/ckan.conf
COPY config/crontab /etc/cron.d/ckan-cron

RUN crontab -u ckan /etc/cron.d/ckan-cron

COPY --chown=ckan-sys:ckan-sys docker-entrypoint.d/* /docker-entrypoint.d/
COPY --chown=ckan-sys:ckan-sys patches ${APP_DIR}/patches
COPY --chown=ckan-sys:ckan-sys setup/prerun.py ${APP_DIR}
COPY --chown=ckan-sys:ckan-sys setup/start_ckan.sh ${APP_DIR}

# libsqlite3-0 is pinned for CVE-2025-6965: remove the pin once the ckan base image ships the fix
# (https://github.com/ckan/ckan-docker/issues/231).
RUN apt-get update \
    && apt-get install -y --no-install-recommends libsqlite3-0=3.40.1-2+deb12u2 \
    && rm -rf /var/lib/apt/lists/*

USER ckan

RUN for d in $APP_DIR/patches/*; do \
    if [ -d $d ]; then \
    for f in `ls $d/*.patch | sort -g`; do \
    cd $SRC_DIR/`basename "$d"` && echo "$0: Applying patch $f to $SRC_DIR/`basename $d`"; patch -p1 < "$f" ; \
    done ; \
    fi ; \
    done

USER root
