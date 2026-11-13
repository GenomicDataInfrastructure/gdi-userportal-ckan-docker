# SPDX-FileCopyrightText: 2006-2024 Open Knowledge Foundation and contributors
# SPDX-FileContributor: PNED G.I.E.
#
# SPDX-License-Identifier: AGPL-3.0-only

import os
import sys
import subprocess
import psycopg2
try:
    from urllib.request import urlopen
    from urllib.error import URLError
except ImportError:
    from urllib2 import urlopen
    from urllib2 import URLError

import time
import re
import json

ckan_ini = os.environ.get("CKAN_INI", "/srv/app/ckan.ini")

RETRY = 5


def update_plugins():

    plugins = os.environ.get("CKAN__PLUGINS", "")
    print(("[prerun] Setting the following plugins in {}:".format(ckan_ini)))
    print(plugins)
    cmd = ["ckan", "config-tool", ckan_ini, "ckan.plugins = {}".format(plugins)]
    subprocess.check_output(cmd, stderr=subprocess.STDOUT)
    print("[prerun] Plugins set.")
    
    
def update_database():

    sqlalchemy_url = os.environ.get("CKAN_SQLALCHEMY_URL", "")
    print(("[prerun] Setting the SqlAlchemy URL in {}:".format(ckan_ini)))
    print(sqlalchemy_url)
    cmd = [
        "ckan",
        "config-tool",
        ckan_ini,
        "sqlalchemy.url = {}".format(sqlalchemy_url),
    ]
    subprocess.check_output(cmd, stderr=subprocess.STDOUT)
    print("[prerun] SqlAlchemy URL set.")


def check_main_db_connection(retry=None):

    conn_str = os.environ.get("CKAN_SQLALCHEMY_URL")
    if not conn_str:
        print("[prerun] CKAN_SQLALCHEMY_URL not defined, not checking db")
        return
    return check_db_connection(conn_str, retry)


def check_db_connection(conn_str, retry=None):

    if retry is None:
        retry = RETRY
    elif retry == 0:
        print("[prerun] Giving up after {} tries...".format(RETRY))
        sys.exit(1)

    try:
        connection = psycopg2.connect(conn_str)

    except psycopg2.Error as e:
        print(str(e))
        print("[prerun] Unable to connect to the database, waiting...")
        time.sleep(10)
        check_db_connection(conn_str, retry=retry - 1)
    else:
        connection.close()


def check_solr_connection(retry=None):

    if retry is None:
        retry = RETRY
    elif retry == 0:
        print("[prerun] Giving up after {} tries...".format(RETRY))
        sys.exit(1)

    url = os.environ.get("CKAN_SOLR_URL", "")
    search_url = "{url}/schema/name?wt=json".format(url=url)

    try:
        connection = urlopen(search_url)
    except URLError as e:
        print(str(e))
        print("[prerun] Unable to connect to solr, waiting...")
        time.sleep(10)
        check_solr_connection(retry=retry - 1)
    else:
        conn_info = connection.read()
        schema_name = json.loads(conn_info)
        if 'ckan' in schema_name['name']:
            print('[prerun] Successfully connected to solr and CKAN schema loaded')
        else:
            print('[prerun] Successfully connected to solr, but CKAN schema not found')


def init_db():

    # `db init` is idempotent and required for a fresh database.
    # `db upgrade` applies any pending migrations.
    print("[prerun] Initializing or upgrading db - start")
    try:
        subprocess.check_output(["ckan", "-c", ckan_ini, "db", "init"], stderr=subprocess.STDOUT)
        subprocess.check_output(["ckan", "-c", ckan_ini, "db", "upgrade"], stderr=subprocess.STDOUT)
        print("[prerun] Initializing or upgrading db - end")
    except subprocess.CalledProcessError as e:
        if "OperationalError" in str(e.output):
            print("[prerun] Database not ready, waiting a bit before exit...")
            time.sleep(5)
            sys.exit(1)
        else:
            print(str(e))
            print(e.output)
            raise e


def run_term_translation_migrations(retry=None):
    """
    Run the gdi-userportal term translation migrations.

    This must run *after* CKAN DB init/upgrade so the core `term_translation`
    table exists. The migration runner itself is idempotent and will skip
    already-applied versions.
    """
    plugins = os.environ.get("CKAN__PLUGINS", "")
    if "gdi_userportal" not in plugins:
        print("[prerun] gdi_userportal plugin not enabled; skipping term translation migrations")
        return

    if retry is None:
        retry = 10
    elif retry == 0:
        print("[prerun] Term translation migrations failed after retries")
        sys.exit(1)

    cmd = ["ckan", "-c", ckan_ini, "gdi-userportal", "translations", "migrate"]
    print("[prerun] Running term translation migrations")
    try:
        subprocess.check_output(cmd, stderr=subprocess.STDOUT)
        print("[prerun] Term translation migrations complete")
    except subprocess.CalledProcessError as e:
        output = ""
        try:
            output = (e.output or b"").decode("utf-8", errors="replace")
        except Exception:
            output = str(e.output)

        # If the schema isn't initialized yet, try to init/upgrade DB then retry.
        if ("term_translation" in output) and (("does not exist" in output) or ("UndefinedTable" in output)):
            print("[prerun] term_translation table missing; initializing/upgrading CKAN DB and retrying migrations")
            # Failures are not fatal here: the migration is retried below, and its error is
            # printed if it still fails. db init is idempotent.
            for db_args in (["init"], ["upgrade"], ["upgrade", "-p", "harvest"]):
                try:
                    subprocess.check_output(["ckan", "-c", ckan_ini, "db"] + db_args, stderr=subprocess.STDOUT)
                except subprocess.CalledProcessError as db_error:
                    print("[prerun] 'ckan db {}' failed, continuing:".format(" ".join(db_args)))
                    print(db_error.output.decode("utf-8", errors="replace") if db_error.output else str(db_error))
        else:
            print("[prerun] Term translation migrations failed, will retry")
            print(output)

        time.sleep(3)
        run_term_translation_migrations(retry=retry - 1)


def init_db_harvest():
    db_command = ["ckan", "-c", ckan_ini, "db", "upgrade", "-p", "harvest"]
    print("[prerun] Initializing or upgrading harvest db - start")
    try:
        subprocess.check_output(db_command, stderr=subprocess.STDOUT)
        print("[prerun] Initializing or upgrading harvest db - end")
    except subprocess.CalledProcessError as e:
        if "OperationalError" in str(e.output):
            print(e.output)
            print("[prerun] Database not ready, waiting a bit before exit...")
            time.sleep(5)
            sys.exit(1)
        else:
            print(str(e))
            print(e.output)
            raise e


def create_sysadmin():

    name = os.environ.get("CKAN_SYSADMIN_NAME")
    password = os.environ.get("CKAN_SYSADMIN_PASSWORD")
    email = os.environ.get("CKAN_SYSADMIN_EMAIL")

    if name and password and email:

        # Check if user exists
        command = ["ckan", "-c", ckan_ini, "user", "show", name]

        out = subprocess.check_output(command)
        if b"User:None" not in re.sub(rb"\s", b"", out):
            print("[prerun] Sysadmin user exists, skipping creation")
            return

        # Create user
        command = [
            "ckan",
            "-c",
            ckan_ini,
            "user",
            "add",
            name,
            "password=" + password,
            "email=" + email,
        ]

        returncode = subprocess.call(command)
        if returncode == 0:
            print("[prerun] Created user {0}".format(name))
        else:
            print("[prerun] Creating user {0} failed (exit code {1})".format(name, returncode))

        # Make it sysadmin
        command = ["ckan", "-c", ckan_ini, "sysadmin", "add", name]

        returncode = subprocess.call(command)
        if returncode == 0:
            print("[prerun] Made user {0} a sysadmin".format(name))
        else:
            print("[prerun] Making user {0} a sysadmin failed (exit code {1})".format(name, returncode))

        # cleanup permissions
        # We're running as root before pivoting to uwsgi and dropping privs
        data_dir = "%s/storage" % os.environ['CKAN_STORAGE_PATH']

        command = ["chown", "-R", "ckan:ckan-sys", data_dir]
        subprocess.call(command)
        print("[prerun] Ensured storage directory is owned by ckan")

if __name__ == "__main__":

    maintenance = os.environ.get("MAINTENANCE_MODE", "").lower() == "true"

    if maintenance:
        print("[prerun] Maintenance mode, skipping setup...")
    else:
        update_plugins()
        update_database()
        check_main_db_connection()
        init_db()
        init_db_harvest()
        run_term_translation_migrations()
        check_solr_connection()
        create_sysadmin()