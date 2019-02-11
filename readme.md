## docker autoheal

Monitors and restarts unhealthy docker containers. Built with docker-compose in mind.

NOTE: Requires implemented health checks on your containers. [Docker Docs - HEALTHCHECK](https://docs.docker.com/engine/reference/builder/#healthcheck)

### Usage 
#### docker

```sh
docker run -d \
    --name autoheal \
    --restart=always \
    -e COMPOSE_MODE=true \
    -e AUTOHEAL_LABEL=PHOENIX \
    -e AUTOHEAL_LABEL_VALUE=true \
    -e AUTOHEAL_DELAY=0 \
    -e AUTOHEAL_INTERVAL=5 \
    -e RPC_TIMEOUT=30 \
    -e STOP_TIMEOUT=10 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    willfarrell/autoheal
```

#### docker-compose

```yml
  autoheal:
    restart: always
    image: willfarrell/autoheal
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      - COMPOSE_MODE=true
      - AUTOHEAL_LABEL=PHOENIX
      - AUTOHEAL_LABEL_VALUE=true
      - AUTOHEAL_DELAY=0
      - AUTOHEAL_INTERVAL=5
      - RPC_TIMEOUT=30
      - STOP_TIMEOUT=10
```

### Configuration

Configuration is possible through env variables. Container supports these env variables:

```conf
# values defined here are default ones
AUTOHEAL_DELAY=0                    # Sets time to wait before first check for unhealthy containers
AUTOHEAL_INTERVAL=5                 # Interval between checks
AUTOHEAL_LABEL=autoheal             # Label used to filter out containers (only containers with this label are going to be auto healed)
AUTOHEAL_LABEL_VALUE=true           # Required value of AUTOHEAL_LABEL value to perform auto heal

DOCKER_SOCKET=/var/run/docker.sock  # Path to docker socket 
RPC_TIMEOUT=30                      # Timeout for call to docker daemon
STOP_TIMEOUT=10                     # Timeout for container to stop on restart (useful when you need more time for container to finish shutdown)
COMPOSE_MODE=false                  # If auto heals containers with matching compose project name as this container carries 
                                    # COMPOSE_MODE + AUTOHEAL_LABEL can be combined to auto heal specific containers in compose project

# shims to provide compatibility with willfarrell/autoheal
# shims are always overwritten byt above variables if defined
AUTOHEAL_CONTAINER_LABEL=autoheal   # Same as AUTOHEAL_LABEL
AUTOHEAL_START_PERIOD=0             # Same as AUTOHEAL_DELAY
DOCKER_SOCK=/var/run/docker.sock    # Same as DOCKER_SOCKET
```

### Testing 

```sh
docker build -t autoheal .

docker run -d \
    -e COMPOSE_MODE=true \
    -e AUTOHEAL_LABEL=PHOENIX \
    -e AUTOHEAL_LABEL_VALUE=true \
    -e AUTOHEAL_DELAY=0 \
    -e AUTOHEAL_INTERVAL=5 \
    -e RPC_TIMEOUT=30 \
    -e STOP_TIMEOUT=10 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    autoheal  
```    