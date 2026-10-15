# CS 1.6 LAN servers

| Server  | Port  | Config dir         |
|---------|-------|--------------------|
| Classic | 27015 | `servers/classic/` |
| Fun     | 27016 | `servers/fun/`     |

Image: `debian:trixie-slim` + HLDS (Steam app 90, `steam_legacy` branch) with
ReHLDS, ReGameDLL, Metamod-R, AMX Mod X 1.9 and ReAPI. Versions are build args
at the top of the `Dockerfile`. Host networking, so the servers show up in the
in-game LAN tab.

```sh
docker compose up -d --build     # build + start
docker compose logs -f cs16-fun  # console output
docker attach cs16-classic       # server console (detach: Ctrl-P Ctrl-Q)
docker compose restart           # apply changed configs / new maps
docker compose build --no-cache  # re-download HLDS and addons
```

## For players

Type in chat:

| Command                 | What                                         |
|-------------------------|----------------------------------------------|
| `/menu`                 | menu with everything below (`bind F3 lanmenu`) |
| `rtv`                   | rock the vote: map vote now once 60% of the players typed it |
| `/maps` or part of a name (`dust`) | nominate a map for the next vote |
| `/votemode`             | vote for Classic / Deathmatch / GunGame / GunGame FFA      |
| `/votekick`             | vote to kick a player (5 min IP ban)         |
| `timeleft`, `nextmap`   | info                                         |
| `/rank`, `/top15`, `/stats` | stats                                    |

A map vote starts automatically 2 minutes before the timelimit ends
(in GunGame: when someone wins), through `rtv`, or by an admin. It shows up
to 8 maps (nominations first, the 3 last played maps are left out) plus
"extend". The vote ends after 10 seconds or once everyone has voted. If no map
gets more than 50%, a runoff between the two best follows. Settings:
`shared/addons/amxmodx/configs/map_manager.cfg`.

## Admins

List admins in `admins.env` (both servers; create it from
`admins.env.example`, it is not in git), then `docker compose up -d`
(no rebuild; `restart` does not re-read env files):

```
CS_ADMINS=Alice:secret, 192.168.1.10, Bob:pw123:cfju
```

Entries are `name:password` (the player types `setinfo _pw "secret"` in the
console once), `name` alone (no password, anyone with that name is admin) or
an IP; append `:flags` to limit the rights (see the comments in the file).
All players have the same `STEAM_ID_LAN` on a LAN server, so SteamIDs can't be
used. `shared/addons/amxmodx/configs/users.ini` works as well.

- `amxmodmenu` in the console: admin menu (kick, ban, slap, team, maps,
  cvars, weapon restrictions, game modes, ...)
- `mapm_start_vote` in the console, "Start map vote" in `/menu` or
  `amxmodmenu`: start a map vote now (`mapm_stop_vote` cancels it)
- `say /mode`: switch the game mode straight away
- `amx_gamemode gungame` in the console or rcon

## Bots

The CS bots built into ReGameDLL fill the teams up to 10 players (humans +
bots) in every mode. They leave as humans join and only come once a human is
on the server.

Admins change this in game with `/bots` (also in `/menu` and `amxmodmenu`):
on/off, fill up to N players, difficulty, weapons (all / pistols / snipers /
knives), radio chatter, kick all. Changes last until the server restarts;
defaults are in `shared/addons/amxmodx/configs/plugins/lan_bots.cfg`. To have
no bots in a mode, set `lan_bots_allowed 0` in its `modes/<mode>.cfg`.

Bots need a navigation mesh per map. The first time bots play a map the
server generates it (about 20 seconds, the game goes on meanwhile) and saves
it in `navs/`, shared by both servers. A `.nav` that comes with a custom map
(in `maps/`) is used as is.

## Game modes

| Mode        | What                                                    | Plugin | Config |
|-------------|---------------------------------------------------------|--------|--------|
| classic     | normal rounds                                           | -      | `modes/classic.cfg` |
| deathmatch  | free-for-all, instant respawn, choose your weapons      | [ReDeathmatch](https://github.com/ReDeathmatch/ReDeathmatch_AMXX) | `redm/gamemode_deathmatch.json`, `modes/deathmatch.cfg` |
| gungame     | teams, instant respawn, next weapon for every kill      | [ReGG](https://github.com/d3m37r4/regg) | `regg/regg-main.cfg`, `regg/regg-levels.ini`, `modes/gungame.cfg` |
| gungame_ffa | GunGame free-for-all with random spawns and 2 s spawn protection | ReGG + `lan_gg_ffa` | as gungame, `modes/gungame_ffa.cfg` |

(paths relative to `addons/amxmodx/configs/`). `MODE` in docker-compose.yml
is the mode a server starts in; switching restarts the current map. Modes
are defined in `shared/addons/amxmodx/configs/lan_modes.ini`.

To change a mode's config, copy it from the container into the overlay,
e.g. `docker cp cs16-fun:/home/steam/hlds/cstrike/addons/amxmodx/configs/regg/regg-main.cfg shared/addons/amxmodx/configs/regg/`.

## Files

```
Dockerfile, entrypoint.sh, docker-compose.yml
admins.env          AMX Mod X admins (CS_ADMINS)
plugins/            own AMXX plugins, compiled during the build
  lan_menu.sma        /menu
  lan_votekick.sma    /votekick
  lan_modes.sma       game modes
  lan_bots.sma        bots, /bots
  lan_gg_ffa.sma      starts ReGG in free-for-all (gungame_ffa mode)
shared/             copied over cstrike/ on both servers
  addons/amxmodx/configs/
    plugins.ini       AMXX plugins (MapManager is in plugins-map_manager.ini)
    users.ini         admins
    map_manager.cfg   map vote settings
    lan_modes.ini, modes/
logs/<name>/        hlds and AMXX logs (kept across restarts/rebuilds)
navs/               bot navigation meshes, generated by the servers
servers/<name>/     copied over cstrike/ after shared/
  server.cfg, maps/, *.wad, sound/, models/, ... (mapcycle.txt optional)
```

On every start, `shared/` and then `servers/<name>/` are copied over `cstrike/`
in the container. Any file can be overridden this way, keeping the cstrike
folder layout.

## Maps

The 25 maps of CS 1.6 (de_dust, de_dust2, de_inferno, cs_office, ...) come
with the server, only custom maps have to be added:

```
servers/fun/
  maps/fy_iceworld.bsp
  de_vegas.wad             # wads the map needs go into the cstrike root
  sound/... models/... gfx/...
```

then `docker compose restart cs16-fun`. Maps in `shared/maps/` are available
on both servers. Clients download missing files from the server
(`sv_allowdownload 1`).

The map list is built on every start from what is installed, depending on
`MAPS` in docker-compose.yml:

| `MAPS`   | Maps                                      | Used by |
|----------|-------------------------------------------|---------|
| `stock`  | the maps that come with CS 1.6            |         |
| `custom` | maps in `shared/maps/` and `servers/<name>/maps/` | fun |
| `all`    | both                                      |         |

To pick the maps (and their order) yourself, create
`servers/<name>/mapcycle.txt` with one map per line; it replaces the automatic
list. The classic server has one with the 8 most played stock maps; delete it
to get all 25. The vote list (`maps.ini`) always follows the map list.

Maps that need a `.wad` that is missing are skipped (see
`docker compose logs`); otherwise hlds would shut down with
`couldn't open xyz.wad`. If the start map (`MAP` in docker-compose.yml) is not
playable, the first map of the list is used.

## Adding AMXX plugins

Put the `.amxx` in `shared/addons/amxmodx/plugins/` (or a server's
`addons/amxmodx/plugins/`), add it to `plugins.ini` and restart. Or put the
`.sma` in `plugins/` and add it to the compile loop in the `Dockerfile`.
