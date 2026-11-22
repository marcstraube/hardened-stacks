# AdGuard Home

Network-wide DNS ad and tracker blocker. See the
[AdGuard Home wiki](https://github.com/AdguardTeam/AdGuardHome/wiki).

The container uses the host network, so DNS (port 53) is reachable from the LAN. The configuration
(`conf/AdGuardHome.yaml`) is created by the setup wizard on first start and is not part of this repository.

## First Start

1. `./stacks deploy adguard-home`
2. Open the setup wizard on `http://<host>:3000`. Port 3000 must be free during setup — stop the
   monitoring stack (Grafana) temporarily if it is running.
3. In the wizard:
   - **Admin web interface:** `127.0.0.1`, port `3001` (only reachable through the reverse proxy)
   - **DNS server:** all interfaces, port `53`
4. Add the reverse proxy entry for port 3001.
5. Hand out the host IP as DNS server in the DHCP settings of your router.

The router usually distributes only one DNS server, so DNS is unavailable for the whole network while
the container restarts. Run updates when the network is quiet.

## Recommended Settings

All settings can be changed in the web interface without a restart.

### Settings → DNS settings

| Setting                           | Value                                       | Why                                                                                                                                   |
| --------------------------------- | ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| Upstream DNS servers              | `https://dns.quad9.net/dns-query`           | Encrypted (DoH), no logging, blocks known malware and phishing domains                                                                |
|                                   | `[/fritz.box/]192.168.1.1` (example)        | Local names of the router go to the router                                                                                            |
| Upstream mode                     | Load balancing                              | "Fastest IP address" queries all upstreams and probes the answers — no benefit with one upstream                                      |
| Fallback DNS servers              | `9.9.9.9`, `149.112.112.112`                | Used when the DoH upstream fails, same filtering as above                                                                             |
| Bootstrap DNS servers             | `9.9.9.9`, `149.112.112.112`, `2620:fe::fe` | Resolve the hostname of the DoH upstream                                                                                              |
| Private reverse DNS servers       | IP of the router, e.g. `192.168.1.1`        | Shows device names instead of IPs in the query log and statistics                                                                     |
| Use private reverse DNS resolvers | enabled                                     | Required for the setting above                                                                                                        |
| Rate limit                        | `20`                                        | Per client, see below                                                                                                                 |
| Subnet prefix length (IPv4/IPv6)  | `32` / `128`                                | The default (`24` / `56`) shares one limit between all devices of the LAN                                                             |
| Enable DNSSEC                     | enabled                                     | Requests DNSSEC data from the upstream and marks validated answers                                                                    |
| Cache                             | enabled                                     |                                                                                                                                       |
| Optimistic caching                | enabled                                     | Serves expired entries immediately and refreshes them in the background; keeps known domains working when the upstream is unavailable |

Quad9 also offers `dns10.quad9.net` without malware blocking. To bypass the filter for a single domain,
add `[/example.com/]https://dns10.quad9.net/dns-query` to the upstream servers.

### Settings → General settings

| Setting    | Value   | Why                                                    |
| ---------- | ------- | ------------------------------------------------------ |
| Query log  | 30 days | 90 days can grow to several GB on a busy network       |
| Statistics | 30 days | The statistics database stays small (a few hundred KB) |

### Filters → DNS blocklists

A small set of well-maintained lists blocks most ads and trackers with few false positives, e.g.
*AdGuard DNS filter*, *OISD Blocklist Small* and *Steven Black's List*. More lists mainly add false
positives.
