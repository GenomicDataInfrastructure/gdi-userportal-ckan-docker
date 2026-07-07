# SPDX-FileCopyrightText: 2006-2024 Open Knowledge Foundation and contributors
# SPDX-FileContributor: PNED G.I.E.
# SPDX-FileContributor: Stichting Health-RI
#
# SPDX-License-Identifier: AGPL-3.0-only

FROM ckan/ckan-base:2.11.5

USER root
# Only give the ckan user write access to the site-packages/bin directories themselves (so pip can
# add the new ckanext-* packages/console-scripts below), plus a recursive chown of the specific
# pip/setuptools/wheel trees that get upgraded in place further down.
RUN chown -R ckan:ckan-sys ${APP_DIR} \
    && chown -R ckan:ckan-sys /usr/local/lib/python3.10/site-packages \
    && chown -R ckan:ckan-sys /usr/local/bin
USER ckan

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_ROOT_USER_ACTION=ignore \
    PIP_SRC=${APP_DIR}/src

RUN set -eux; \
    # setuptools>=82 dropped the legacy easy_install/`setup.py develop` codepath that pip's
    # editable installs (`pip install -e git+...`) fall back to for the setup.py-only CKAN
    # extensions installed below, breaking those installs; pin below it until they add PEP 517 support.
    python -m pip install --upgrade --no-cache-dir pip 'setuptools<82' wheel; \
    python -m pip install --no-cache-dir \
        -e git+https://github.com/GenomicDataInfrastructure/gdi-userportal-ckanext-gdi-userportal.git@v1.12.0#egg=ckanext-gdi-userportal \
        -e git+https://github.com/GenomicDataInfrastructure/gdi-userportal-ckanext-dcat.git@v2.4.2#egg=ckanext-dcat \
        -e git+https://github.com/ckan/ckanext-dataset-series.git@v0.1.1#egg=ckanext-dataset-series \
        -e git+https://github.com/ckan/ckanext-harvest.git@v1.6.2#egg=ckanext-harvest \
        'ckanext-scheming[requirements] @ git+https://github.com/ckan/ckanext-scheming.git@release-3.1.0' \
        -e git+https://github.com/GenomicDataInfrastructure/gdi-userportal-ckanext-fairdatapoint.git@v1.6.12#egg=ckanext-fairdatapoint \
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
            python -m pip install -r "${req_file}"; \
        fi; \
    done; \
    python -m pip install --no-cache-dir \
        pytest-ckan \
        factory-boy>=2; \
    python -m pip check

USER root

### Install everything we need for the harvester
# Install cron and supervisor. 
RUN apt-get update && apt-get install -y --no-install-recommends \
    cron \
    supervisor \
    libsqlite3-0=3.40.1-2+deb12u2 \
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

USER ckan

RUN for d in $APP_DIR/patches/*; do \
    if [ -d $d ]; then \
    for f in `ls $d/*.patch | sort -g`; do \
    cd $SRC_DIR/`basename "$d"` && echo "$0: Applying patch $f to $SRC_DIR/`basename $d`"; patch -p1 < "$f" ; \
    done ; \
    fi ; \
    done

USER root
