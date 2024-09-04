#!/usr/bin/env bash

set -e

# performs mongod upgrades and engine migrations as configured
migrate_kvstore() {
    {{ splunk_home }}/bin/splunk migrate migrate-kvstore-36-40

    {% if migrate_kvstore is defined %}
    {{ splunk_home }}/bin/splunk start --accept-license --answer-yes --no-prompt $@
    {{ splunk_home }}/bin/splunk stop
    {{ splunk_home }}/bin/splunk migrate kvstore-storage-engine --target-engine wiredTiger
    {% endif %}

    {% if upgrade_kvstore is defined %}
    {{ splunk_home }}/bin/splunk migrate migrate-kvstore
    {% endif %}
}

# starts Splunk using the CLI
start_splunk() {
    exec {{ splunk_home }}/bin/splunk start --nodaemon --accept-license --answer-yes --no-prompt $@
}

# stops Splunk using the CLI
stop_splunk() {
    exec {{ splunk_home }}/bin/splunk stop $@ 2>/dev/null || true
}

# calls stop when SIGINT and SIGTERM are received for graceful shutdowns in Docker Swarm
trap stop SIGINT SIGTERM

# restarts Splunk using the CLI
restart_splunk() {
    exec {{ splunk_home }}/bin/splunk restart $@ 2>/dev/null || true
}

# BEGIN EXECUTION HERE

case "${1}" in
    "migrate_kvstore")
        migrate_kvstore
    ;;
    "start_splunk"|"")
        migrate_kvstore
        start
    ;;
    "stop_splunk")
        stop
    ;;
    "restart_splunk")
        restart
    ;;
esac
