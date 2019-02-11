#!/bin/sh
set -e

# shims to provide backward compatibility with original autoheal
# shellcheck disable=SC2039
AUTOHEAL_LABEL=${AUTOHEAL_LABEL:"$AUTOHEAL_CONTAINER_LABEL"}
# shellcheck disable=SC2039
AUTOHEAL_DELAY=${AUTOHEAL_DELAY:"$AUTOHEAL_START_PERIOD"}
# shellcheck disable=SC2039
DOCKER_SOCKET=${DOCKER_SOCKET:"$DOCKER_SOCK"}
# shellcheck disable=SC2039
RPC_TIMEOUT=${RPC_TIMEOUT:"$CURL_TIMEOUT"}

# INIT CONFIGURATION
AUTOHEAL_DELAY=${AUTOHEAL_DELAY:-0}
AUTOHEAL_INTERVAL=${AUTOHEAL_INTERVAL:-5}
AUTOHEAL_LABEL_VALUE=${AUTOHEAL_LABEL_VALUE:=true}

DOCKER_SOCKET=${DOCKER_SOCKET:-/var/run/docker.sock}
RPC_TIMEOUT=${RPC_TIMEOUT:-30}
STOP_TIMEOUT=${STOP_TIMEOUT:-10}
COMPOSE_MODE=${COMPOSE_MODE:-false}

# SIGTERM-handler
term_handler() {
  exit 143; # 128 + 15 -- SIGTERM
}

docker_rpc() {
  curl --max-time "${RPC_TIMEOUT}" --no-buffer -s --unix-socket "$DOCKER_SOCKET" "$@"
}

trap 'kill ${!}; term_handler' TERM

if [ "$1" = 'autoheal' ] && [ -e "$DOCKER_SOCKET" ]; then
  
    if [ "$COMPOSE_MODE" = "true" ]; then
        SELF_ID=$(grep "docker" /proc/self/cgroup | head -1 | sed 's/.*\/docker\///g')
        
        LABELS=$(docker_rpc "http://localhost/containers/$SELF_ID/json" | jq '.Config.Labels | to_entries[] | select( .key | contains("project") and contains("compose"))')
        PROJECT_KEY=$(printf "%s" "$LABELS" | jq .key -r)
        PROJECT_NAME=$(printf "%s" "$LABELS" | jq .value -r)
        
        labelFilter=",\"label\":\[\"$PROJECT_KEY=$PROJECT_NAME\"\]"
        if [ -n "$AUTOHEAL_LABEL" ] && [ ! "$AUTOHEAL_LABEL" = "all" ]; then
            labelFilter="$labelFilter,\"label\":\[\"$AUTOHEAL_LABEL=$AUTOHEAL_LABEL_VALUE\"\]"
        fi
    elif [ "$AUTOHEAL_LABEL" = "all" ]; then
        labelFilter=""
    else
        labelFilter=",\"label\":\[\"${AUTOHEAL_LABEL:=autoheal}=$AUTOHEAL_LABEL_VALUE\"\]"
    fi

    printf "Monitoring containers for unhealthy status in %s second(s)\n" "$AUTOHEAL_DELAY"
    sleep "$AUTOHEAL_DELAY"

    while true; do
        sleep "$AUTOHEAL_INTERVAL"
        
        apiUrl="http://localhost/containers/json?filters=\{\"health\":\[\"unhealthy\"\]$labelFilter\}"
        docker_rpc "$apiUrl" | jq -r 'foreach .[] as $CONTAINER([];[]; $CONTAINER | .Id, .Names[0])' | \
        while read -r CONTAINER_ID && read -r CONTAINER_NAME; do
            CONTAINER_ID="$(printf "%s" "$CONTAINER_ID" | awk '{print substr($0, 0, 12);}')"
            DATE=$(date +%d-%m-%Y" "%H:%M:%S)
            
            if [ ! "$CONTAINER_NAME" = "null" ]; then
                printf "%s Container %s (%s) found to be unhealthy - Restarting container now" "$DATE" "$CONTAINER_NAME" "$CONTAINER_SHORT_ID"
                docker_rpc -f -XPOST "http://localhost/containers/$CONTAINER_ID/restart?t=$STOP_TIMEOUT" || \
                    printf "%s Restarting container %s failed" "$DATE" "$CONTAINER_SHORT_ID"
            fi
        done
    done

else
  exec "$@"
fi