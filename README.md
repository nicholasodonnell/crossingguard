<img src="logo/banner.png" />

**Crossingguard** is a Dockerized [Traefik](https://doc.traefik.io/traefik/) implementation for proxying Docker containers over SSL.

### Requirements

- [Docker](https://www.docker.com/get-started)
- [Docker Compose](https://docs.docker.com/compose/)
- [GNU make](https://www.gnu.org/software/make/)

### Services

- **Traefik** - HTTP reverse proxy.
- **Grafana** - Analytic visualization.
- **Prometheus** - Metrics store.

## Installation

1. Create a `.env` file using [`.env.example`](.env.example) as a reference: `cp -n .env{.example,}`.
2. Create a `docker-compose.override.yml` file using [`docker-compose.override.example.yml`](docker-compose.override.example.yml) as a reference: `cp -n docker-compose.override{.example,}.yml`.
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
| `GRAFANA_DATA_PATH`             | Host location for Grafana data.                                                                             |
| `GRAFANA_USER`                  | Grafana admin username.                                                                                     |
| `GRAFANA_PASSWORD`              | Grafana admin password.                                                                                     |
| `PROMETHEUS_DATA_PATH`          | Host location for Prometheus data.                                                                          |
| `LETSENCRYPT_EMAIL`             | Email so that Let's Encrypt can warn you about expiring certificates and allow you to recover your account. |
| `TRAEFIK_LETSENCRYPT_DATA_PATH` | Host data path for Let's Encrypt configurations and certificates.                                           |
| `TRAEFIK_HTTP_PORT`             | Locally exposed ports for HTTP on the host.                                                                 |
| `TRAEFIK_HTTPS_PORT`            | Locally exposed ports for HTTPS on the host.                                                                |
| `TRAEFIK_PILOT_TOKEN`           | A multi-digit key that identifies a Traefik Pilot instance.                                                 |

## Proxying Docker Containers

After following the steps above you can create new docker containers that will automatically proxy any connections over SSL. Once this collection is running, simply start a container you want proxyed attached to your `EXTERNAL_NETWORK` with the following labels:

```
- "traefik.enable=true"
- "traefik.http.routers.<name>.entrypoints=websecure"
- "traefik.http.routers.<name>.rule=Host(`<domain>`)"
- "traefik.http.routers.<name>.tls.certresolver=letsencrypt"
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
  --label "traefik.http.routers.app.tls.certresolver=letsencrypt" \
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
      - "traefik.http.routers.app.tls.certresolver=letsencrypt"
      - "traefik.http.services.app.loadbalancer.server.port=80"
    image: nginx
    networks:
      - crossingguard

networks:
  crossingguard:
    external:
      name: crossingguard
```

## Securing the Traefik dashboard

The Traefik dashboard is available using a service called `api@internal`. All you have to do is to expose this service.
To expose Traefik to the outside world, it is essential to add an authentication system otherwise anyone can get in.

The securely expose the Traefik dashboard, modify these traefik labels in your `docker-compose.override.yml` file:

```yaml
# Traefik dashboard
- "traefik.enable=true"
- "traefik.http.routers.traefik.entrypoints=websecure"
- "traefik.http.routers.traefik.rule=Host(`<domain>`)"
- "traefik.http.routers.traefik.service=api@internal"
- "traefik.http.routers.traefik.tls.certresolver=letsencrypt"
- "traefik.http.services.traefik.loadbalancer.server.port=8080"

# Traefik auth
- "traefik.http.middlewares.traefik-auth.basicauth.users=<username>:<htpasswd>"
- "traefik.http.routers.traefik.middlewares=traefik-auth"
```

Where `<domain>` is your traefik dashboard domain, `<username>` is your http auth username, and `<htpasswd>` is your http auth password.

To generate a http username/password you can use [htpasswd](https://httpd.apache.org/docs/2.4/programs/htpasswd.html) (using `sed` to escape the `$` present in the hash):

```bash
htpasswd -nb admin admin | sed -e s/\\$/\\$\\$/g
```

## Collect and visualize analytics

Traefik metrics are collected by **Prometheus**. To visualize these metrics you must expose the **Grafana** container.

To expose Grafana, simply proxy the container through Traefik by modifying these labels in your `docker-compose.override.yml` file:

```yaml
- "traefik.enable=true"
- "traefik.http.routers.grafana.entrypoints=websecure"
- "traefik.http.routers.grafana.rule=Host(`<domain>`)"
- "traefik.http.routers.grafana.tls.certresolver=letsencrypt"
- "traefik.http.services.grafana.loadbalancer.server.port=3000"
```

Where `<domain>` is your grafana domain. The username and password can be set using the [ENV Options](#env-options) above.

## Advanced Usage

Please see the [traefik docker documentation](https://doc.traefik.io/traefik/providers/docker/).
