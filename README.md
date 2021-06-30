<img src="logo/logo.png" />

**Crossingguard** is a Dockerized [traefik](https://doc.traefik.io/traefik/) implementation for proxying Docker containers over SSL.

### Requirements

- [Docker](https://www.docker.com/get-started)
- [Docker Compose](https://docs.docker.com/compose/)
- [GNU make](https://www.gnu.org/software/make/)

## Installation

1. Create a `.env` file using [`.env.example`](.env.example) as a reference: `cp -n .env{.example,}`.
2. Build the docker images by running `make build`.

## Setup

Before running this collection for the first time you must create the external network by running `make network`.

## Usage

To start the collection:

```
make up
```

To stop the collection:

```
make down
```

To view logs of one or more running services:

```
make logs [service="<service>"] [file="/path/to/log/file"]
```

To build docker images:

```
make build
```

To remove docker images:

```
make clean
```

## ENV Options

| Option                          | Description                                                                                                 |
| ------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| `DOCKER_SOCKET_PATH`            | The host docker socket path.                                                                                |
| `EXTERNAL_NETWORK`              | Name of the external docker network for proxying.                                                           |
| `EXTERNAL_NETWORK_OPTIONS`      | Docker network options when creating the external network.                                                  |
| `LETSENCRYPT_EMAIL`             | Email so that Let's Encrypt can warn you about expiring certificates and allow you to recover your account. |
| `TRAEFIK_LETSENCRYPT_DATA_PATH` | Host data path for Let's Encrypt configurations and certificates.                                           |
| `TRAEFIK_HTTP_PORT`             | Locally exposed ports for HTTP on the host.                                                                 |
| `TRAEFIK_HTTPS_PORT`            | Locally exposed ports for HTTPS on the host.                                                                |

## Proxying Docker Containers

After following the steps above you can create new docker containers that will automatically proxy any connections over SSL. Once this collection is running, simply start a container you want proxyed attached to your `EXTERNAL_NETWORK` with the following labels:

```
- "traefik.enable=true"
- "traefik.http.routers.<name>.entrypoints=websecure"
- "traefik.http.routers.<name>.rule=Host(`<domain>`)"
- "traefik.http.routers.<name>.tls.certresolver=crossingguard"
- "traefik.http.services.<name>.loadbalancer.server.port=<port>"
```

Where `<domain>` is the custom domain to assign to Traefik, `<port>` is the exposed port, and `<name>` is the container name.

#### Examples

```sh
docker run \
  --expose=80 \
  --label "traefik.enable=true" \
  --label "traefik.http.routers.app.entrypoints=websecure" \
  --label "traefik.http.routers.app.rule=Host(`app.example.com`)" \
  --label "traefik.http.routers.app.tls.certresolver=myresolver" \
  --label "traefik.http.services.app.loadbalancer.server.port=80" \
  --name app \
  --network=crossingguard \
  nginx
```

```yml
version: "3.5"
services:
  app:
    container_name: app
    expose:
      - 80
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.app.entrypoints=websecure"
      - "traefik.http.routers.app.rule=Host(`app.example.com`)"
      - "traefik.http.routers.app.tls.certresolver=myresolver"
      - "traefik.http.services.app.loadbalancer.server.port=80"
    image: nginx
    networks:
      - crossingguard

networks:
  crossingguard:
    external:
      name: crossingguard
```

## Advanced Usage

Please see the [traefik docker documentation](https://doc.traefik.io/traefik/providers/docker/).
