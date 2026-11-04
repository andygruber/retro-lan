# laninfo – LAN party info page

Info page and download server for the LAN party: Wi-Fi and server info, one page
per game with downloads, install steps and server addresses, and a list of all
downloads. Light/dark mode, works on phones, needs no internet at the party (no
CDN, everything is in the binary).

```sh
cp .env.example .env            # optional: port, downloads folder, LAN_* variables
docker compose up -d --build    # build + start, then open http://<host>/
docker compose logs -f          # requests and downloads (who downloads what)
docker compose up -d --build    # after changing anything in server/
docker compose down             # stop and remove
```

Build the image once while online (it downloads the Go modules), after that
everything works offline.

| What | Where |
|---|---|
| Port | 80 on the host (`LANINFO_PORT` in `.env`, e.g. `8080`) → 8080 in the container |
| Downloads | `../games` (`GAMES_DIR` in `.env`), mounted read-only |
| Content | `./content`, mounted read-only |

If other PCs can't open the page, open the port in firewalld:
`sudo firewall-cmd --permanent --add-service=http && sudo firewall-cmd --reload`.

## Layout

```
docker-compose.yml
.env.example          port, downloads folder, LAN_* variables
server/               the app (Go): only touch it to change how pages look
content/              everything you edit, re-read on every request
  site.yml            title, colors, variables (Wi-Fi, IP, ...), info cards
  pages/index.md      text on the start page
  pages/*.md          more pages, they show up in the menu (help.md, ...)
  games/*.md          one file per game; _template.md documents all fields
  assets/             images, served at /assets/... (e.g. game covers)
  custom.css          optional, loaded after the built-in styles
```

Edit a file, reload the browser. No restart needed. A typo in YAML shows up as
a yellow box at the top of the page with the file and line.

## Variables

`vars:` in `content/site.yml` (e.g. `wifi_ssid`, `wifi_password`, `server_ip`)
can be used as `{{name}}` in every content file, also in commands:
`open {{server_ip}}:7777`. Unknown names stay visible as `{{name}}`.

- `LAN_<NAME>` environment variables in `.env` override them
  (`LAN_WIFI_PASSWORD=...`), so secrets can stay out of git.
  After changing `.env`: `docker compose up -d`.
- `{{server_ip}}`: empty = the address players used to open this page. That's
  right as long as the game servers run on the same machine as this page.
- `{{host}}`: address of this page incl. port.

The Wi-Fi card's QR code (`qr: wifi`) is built from `wifi_ssid`,
`wifi_password` and `wifi_security` (`WPA`, `WEP`, `nopass`).

## Games

One markdown file per game in `content/games/`, the file name is the URL
(`games/ut99.md` → `/games/ut99`). The YAML header between the `---` lines
holds the facts, the text below is markdown:

```yaml
---
title: Unreal Tournament
short: UT99                 # text on the cover
summary: ...                # text on the game card
platforms: [Windows, Linux]
players: 2–16
order: 10                   # sort order
color: "#c2410c"            # cover color (or image: ut.jpg from assets/)
downloads:
  - file: UT.zip            # relative to the downloads folder
    label: Offline installer
    notes: markdown
servers:
  - name: UT99 LAN Server
    address: "{{server_ip}}:7777"
    join: "open {{server_ip}}:7777"
---
## Install
### Windows
...
### Linux
...
```

- Copy `_template.md` for a new game. Files starting with `_` are ignored,
  `hidden: true` hides a game.
- Headings named *Windows*, *Linux*, *macOS* or *Steam Deck* right after each
  other become tabs; the visitor's system is preselected.
- `> [!NOTE]`, `> [!TIP]`, `> [!WARNING]` (also `IMPORTANT`, `CAUTION`) make
  colored boxes. Code blocks get a copy button.
- A download whose file is missing shows as "Not available yet", and the
  Downloads page names it at the top.
- The Downloads page lists every file in the downloads folder, also ones no
  game references (`show_all_files: false` in `site.yml` to hide those).
  Dot files are never served.

Downloads support HTTP range requests: browsers can resume, `wget -c` /
`curl -C -` too.

## Included games

Written from the files in `../games` and the server setups in `../gameservers`:

| File | Game | Downloads | Server |
|---|---|---|---|
| `ut99.md` | Unreal Tournament GOTY (469f) | `UT.zip` | 7777 ([ut-srv](../gameservers/ut-srv)) |
| `ut2004.md` | Unreal Tournament 2004 (3374) | `UT2004.zip` | 7797 ([ut-srv](../gameservers/ut-srv)) |
| `cs16.md` | Counter-Strike 1.6 | Steam recommended, NextClient as alternative | 27015, 27016 ([cs16-srv](../gameservers/cs16-srv)) |
| `warcraft3.md` | Warcraft III 1.29.2 | zip + keys | – (player hosts) |
| `flatout2.md` | FlatOut 2 (GOG) | `Flatout 2.zip` | – (player hosts) |
| `blur.md` | Blur (DVD image, patch 1.2) | `Blur.zip` | – (player hosts) |
| `mcm2-reborn.md` | Motocross Madness 2: MCM2:Reborn ([fork](https://github.com/andygruber/MCM2Reborn)) | `MCM2 Reborn.zip` | – (player hosts) |
| `nfsu2.md` | NFS Underground 2 UG2.net Edition | `.7z` | – (player hosts) |
| `newer-smbw.md` | Newer Super Mario Bros. Wii PC port ([fork](https://github.com/andygruber/NSMB-Wii-Multiplayer-Recompilation)) | zip | – (player hosts) |

The keys file for Warcraft III is a normal download, so everyone on the LAN can
get it. Remove it from `warcraft3.md` (and the downloads folder) if you'd rather
hand out keys yourself.

## Server

`server/` is a small Go program (net/http, goldmark for markdown, yaml.v3,
go-qrcode). Templates, CSS and JS are in `server/web/` and are built into the
binary, so changes there need `docker compose up -d --build`. For small style
changes, use `content/custom.css` instead (no rebuild).
Options (environment): `LANINFO_ADDR` (`:8080`), `LANINFO_CONTENT`
(`/data/content`), `LANINFO_DOWNLOADS` (`/data/downloads`).
