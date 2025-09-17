# SPDX-FileCopyrightText: 2006-2024 Open Knowledge Foundation and contributors
# SPDX-FileContributor: PNED G.I.E.
# SPDX-FileContributor: Stichting Health-RI
#
# SPDX-License-Identifier: AGPL-3.0-only

FROM ckan/ckan-base:2.11.3

USER root
RUN chown -R ckan:ckan-sys ${APP_DIR}
USER ckan


RUN pip3 install -e git+https://github.com/GenomicDataInfrastructure/gdi-userportal-ckanext-gdi-userportal.git@v1.10.0#egg=ckanext-gdi-userportal && \
    pip3 install -r ${APP_DIR}/src/ckanext-gdi-userportal/requirements.txt && \
    pip3 install -e git+https://github.com/GenomicDataInfrastructure/gdi-userportal-ckanext-dcat.git@v2.3.3#egg=ckanext-dcat && \
    pip3 install -r ${APP_DIR}/src/ckanext-dcat/requirements.txt && \
    pip3 install -e git+https://github.com/GenomicDataInfrastructure/gdi-userportal-ckanext-dataset-series.git@v1.0.0#egg=ckanext-dataset-series && \
    pip3 install -r ${APP_DIR}/src/ckanext-dataset-series/requirements.txt && \
    pip3 install -e git+https://github.com/ckan/ckanext-harvest.git@v1.6.1#egg=ckanext-harvest && \
    pip3 install -r ${APP_DIR}/src/ckanext-harvest/requirements.txt && \
    pip3 install -e git+https://github.com/CivityNL/ckanext-scheming.git@release-3.0.0-civity-1#egg=ckanext-scheming[requirements] && \
    pip3 install -e git+https://github.com/GenomicDataInfrastructure/gdi-userportal-ckanext-fairdatapoint.git@v1.6.0#egg=ckanext-fairdatapoint && \
    pip3 install -r ${APP_DIR}/src/ckanext-fairdatapoint/requirements.txt

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
