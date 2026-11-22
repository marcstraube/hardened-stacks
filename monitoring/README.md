# Monitoring

Prometheus (metrics) and Grafana (dashboards). See the [Prometheus](https://prometheus.io/docs/) and
[Grafana](https://grafana.com/docs/grafana/latest/) documentation.

## Prometheus

Scrape targets are configured in [prometheus/prometheus.yml](prometheus/prometheus.yml). Metrics are kept
for 30 days (`--storage.tsdb.retention.time`). Prometheus is only reachable through the reverse proxy; it
has no authentication of its own.

## Grafana

Log in as `admin` with `GRAFANA_ADMIN_PASSWORD` from `.env`. The password only applies on the first start;
change it later in the web interface.

Configuration is provisioned from [grafana/provisioning](grafana/provisioning/):

| Directory     | Content                                            |
| ------------- | -------------------------------------------------- |
| `datasources` | Prometheus as default data source                  |
| `dashboards`  | Dashboard providers (empty placeholder)            |
| `alerting`    | Alert rules and contact points (empty placeholder) |
| `plugins`     | Plugin apps (empty placeholder)                    |

Grafana logs errors on every start when one of these directories has no valid YAML file, so the
placeholders must stay.

## Ports

Grafana uses port `3000` on `127.0.0.1`. The AdGuard Home setup wizard also needs port 3000 — stop this
stack while setting up AdGuard Home for the first time.
