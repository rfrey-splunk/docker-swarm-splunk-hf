#!/usr/bin/env bash

set -e

# performs mongod upgrades and engine migrations as configured
migrate_kvstore() {
    {{ splunk_home }}/bin/splunk migrate migrate-kvstore-36-40 || true

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
    # replace the process running this script with the process running Splunk
    # note: this "fixes" signal forwarding so that the trap for stop_splunk
    #       should not be needed, however it has been included here in case it
    #       occurs before the exec is complete
    exec {{ splunk_home }}/bin/splunk start --nodaemon --accept-license --answer-yes --no-prompt $@
}

# stops Splunk using the CLI
stop_splunk() {
    {{ splunk_home }}/bin/splunk stop $@ 2>/dev/null || true
}

# calls stop_splunk function when SIGINT and SIGTERM are received
# to allow for graceful shutdowns in Docker Swarm
trap stop_splunk SIGINT SIGTERM

# restarts Splunk using the CLI
restart_splunk() {
    stop_splunk
    start_splunk
}

########################
# BEGIN EXECUTION HERE #
########################

case "${1}" in
    "migrate_kvstore")
        migrate_kvstore
    ;;
    "start"|"") # default
        migrate_kvstore
        start_splunk
    ;;
    "stop")
        stop_splunk
    ;;
    "restart")
        restart_splunk
    ;;
esac
