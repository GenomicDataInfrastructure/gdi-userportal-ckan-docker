# SPDX-FileCopyrightText: 2006-2024 Open Knowledge Foundation and contributors
# SPDX-FileContributor: PNED G.I.E.
# SPDX-FileContributor: Stichting Health-RI
#
# SPDX-License-Identifier: AGPL-3.0-only

FROM ckan/ckan-base:2.11.4

USER root
RUN chown -R ckan:ckan-sys ${APP_DIR}
USER ckan

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_ROOT_USER_ACTION=ignore \
    PIP_SRC=${APP_DIR}/src

RUN set -eux; \
    python -m pip install --upgrade --no-cache-dir pip setuptools wheel; \
    python -m pip install --no-cache-dir \
        -e git+https://github.com/GenomicDataInfrastructure/gdi-userportal-ckanext-gdi-userportal.git@v1.11.6#egg=ckanext-gdi-userportal \
        -e git+https://github.com/GenomicDataInfrastructure/gdi-userportal-ckanext-dcat.git@v2.3.7#egg=ckanext-dcat \
        -e git+https://github.com/GenomicDataInfrastructure/gdi-userportal-ckanext-dataset-series.git@v1.0.0#egg=ckanext-dataset-series \
        -e git+https://github.com/ckan/ckanext-harvest.git@v1.6.1#egg=ckanext-harvest \
        'ckanext-scheming[requirements] @ git+https://github.com/ckan/ckanext-scheming.git@release-3.1.0' \
        -e git+https://github.com/GenomicDataInfrastructure/gdi-userportal-ckanext-fairdatapoint.git@v1.6.3#egg=ckanext-fairdatapoint \
        -e git+https://github.com/ckan/ckanext-fluent.git#egg=ckanext-fluent; \
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
            python -m pip install --no-cache-dir -r "${req_file}"; \
        fi; \
    done; \
    python -m pip check

USER root

### Install everything we need for the harvester
# Install cron and supervisor. 
RUN apt-get update && apt-get install -y --no-install-recommends \
    cron \
    supervisor \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/log/ckan/std /var/log/supervisor /etc/supervisor/conf.d \
    && chown -R ckan:ckan-sys /var/log/ckan /var/log/supervisor /etc/supervisor/conf.d

# Config cron job for harvesting
COPY config/supervisord.conf /etc/supervisord.d/ckan.conf
COPY config/crontab /etc/cron.d/ckan-cron

# Running cron as non-root user and give permission to ckan user
RUN chmod gu+rw /var/run && \
    chmod gu+s /usr/sbin/cron && \
    crontab -u ckan /etc/cron.d/ckan-cron

COPY --chown=ckan-sys:ckan-sys docker-entrypoint.d/* /docker-entrypoint.d/
COPY --chown=ckan-sys:ckan-sys patches ${APP_DIR}/patches
COPY --chown=ckan-sys:ckan-sys setup/prerun.py ${APP_DIR}
COPY --chown=ckan-sys:ckan-sys setup/start_ckan.sh ${APP_DIR}

# CVE-2025-6965 (wait for ckan base to be updated: https://github.com/ckan/ckan-docker/issues/231)
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
