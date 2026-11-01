# Service map

## Contents

- [How to read this](#how-to-read-this)
- [Services](#services)
- [Direct-IP fallbacks](#direct-ip-fallbacks)

## How to read this

Every route is served on **both** `*.krynet.cc` and `*.lan.kkasbi.in`. From this
laptop **use the `.lan.kkasbi.in` column** — `krynet.cc` is blocked by corporate web
filtering. Nothing is lost; the proxy config is identical for both.

The **Upstream** column is what the proxy forwards to. `127.0.0.1` means *the
service runs on Agni itself* (the proxy host) — for those, the direct-IP fallback is
`192.168.0.200:<port>`.

Generated from `home-server/config/caddy/Caddyfile`. If a route changes there, this
table is stale — regenerate rather than hand-edit.

## Services

| Service | URL (use this) | Upstream |
|---|---|---|
| `abs` | `https://abs.lan.kkasbi.in` | `http://192.168.0.100:13378` |
| `adguard` | `https://adguard.lan.kkasbi.in` | `http://192.168.0.100:7000` |
| `adguard2` | `https://adguard2.lan.kkasbi.in` | `http://127.0.0.1:7000` |
| `adsync` | `https://adsync.lan.kkasbi.in` | `http://127.0.0.1:8082` |
| `bazarr` | `https://bazarr.lan.kkasbi.in` | `http://192.168.0.100:6767` |
| `cadvisor2` | `https://cadvisor2.lan.kkasbi.in` | `http://127.0.0.1:8087` |
| `dozzle` | `https://logs.lan.kkasbi.in` | `http://127.0.0.1:8088` |
| `file` | `https://file.lan.kkasbi.in` | `http://127.0.0.1:3923` |
| `flaresolverr` | `https://flare.lan.kkasbi.in` | `http://192.168.0.100:8191` |
| `frigate` | `https://frigate.lan.kkasbi.in` | `http://192.168.0.150:5000` |
| `gatus` | `https://status.lan.kkasbi.in` | `http://127.0.0.1:3001` |
| `gotify` | `https://notify.lan.kkasbi.in` | `http://127.0.0.1:8089` |
| `grafana` | `https://grafana.lan.kkasbi.in` | `http://127.0.0.1:3000` |
| `ha` | `https://ha.lan.kkasbi.in` | `http://127.0.0.1:8123` |
| `hc` | `https://hc.lan.kkasbi.in` | `http://127.0.0.1:8000` |
| `homepage` | `https://home.lan.kkasbi.in` | `http://127.0.0.1:3075` |
| `immich` | `https://photos.lan.kkasbi.in` | `http://192.168.0.100:2283` |
| `ipt` | `https://ipt.lan.kkasbi.in` | `http://192.168.0.100:8001` |
| `jellyfin` | `https://media.lan.kkasbi.in` | `http://192.168.0.100:8096` |
| `jellyseerr` | `https://request.lan.kkasbi.in` | `http://192.168.0.100:5055` |
| `jellystat` | `https://jellystat.lan.kkasbi.in` | `http://192.168.0.100:3005` |
| `litellm` | `https://litellm.lan.kkasbi.in` | `http://192.168.0.150:4000` |
| `nucleus` | `https://finance.lan.kkasbi.in` | `http://192.168.0.100:8081` |
| `ollama` | `https://ollama.lan.kkasbi.in` | `http://192.168.0.150:11434` |
| `ospt` | `https://ospt.lan.kkasbi.in` | `http://192.168.0.100:8992` |
| `ospt2` | `https://ospt2.lan.kkasbi.in` | `http://127.0.0.1:8092` |
| `ow` | `https://ow.lan.kkasbi.in` | `http://192.168.0.150:3999` |
| `paperless` | `https://docs.lan.kkasbi.in` | `http://192.168.0.100:8089` |
| `portainer` | `https://portainer.lan.kkasbi.in` | `https://192.168.0.100:9443` |
| `portainer2` | `https://portainer2.lan.kkasbi.in` | `https://127.0.0.1:9443` |
| `prometheus` | `https://prom.lan.kkasbi.in` | `http://127.0.0.1:9090` |
| `prowlarr` | `https://indexer.lan.kkasbi.in` | `http://192.168.0.100:9696` |
| `qbittorrent` | `https://qb.lan.kkasbi.in` | `http://192.168.0.100:8080` |
| `radarr` | `https://radarr.lan.kkasbi.in` | `http://192.168.0.100:7878` |
| `rss` | `https://rss.lan.kkasbi.in` | `http://192.168.0.100:8086` |
| `sabnzbd` | `https://nzb.lan.kkasbi.in` | `http://192.168.0.100:8085` |
| `sonarr` | `https://sonarr.lan.kkasbi.in` | `http://192.168.0.100:8989` |
| `speedtest` | `https://speed.lan.kkasbi.in` | `http://192.168.0.100:8093` |
| `subgen` | `https://subgen.lan.kkasbi.in` | `http://192.168.0.150:9000` |
| `tdarr` | `https://tdarr.lan.kkasbi.in` | `http://192.168.0.100:8265` |
| `truenas` | `https://server.lan.kkasbi.in` | `http://192.168.0.100:88` |
| `vault` | `https://vault.lan.kkasbi.in` | `http://127.0.0.1:8222` |
| `whisparr` | `https://whisparr.lan.kkasbi.in` | `http://192.168.0.100:6969` |

**43 services.**

## Direct-IP fallbacks

If DNS or the proxy is the problem, go straight to the upstream. Anything listed
above as `127.0.0.1:<port>` is on Agni:

| Instead of | Try |
|---|---|
| `https://<svc>.lan.kkasbi.in` where upstream is `127.0.0.1:P` | `http://192.168.0.200:P` |
| `https://<svc>.lan.kkasbi.in` where upstream is `192.168.0.100:P` | `http://192.168.0.100:P` |
| `https://<svc>.lan.kkasbi.in` where upstream is `192.168.0.150:P` | `http://192.168.0.150:P` |

A direct-IP hit that works while the hostname fails isolates the fault to DNS or
Caddy, not the service.
