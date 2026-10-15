# Unreal Tournament LAN servers (UT99 + UT2004)

| Server | Game port | Also uses             | Web admin | Config dir        |
|--------|-----------|-----------------------|-----------|-------------------|
| UT99   | 7777      | 7778, 8777 (LAN)      | 5080      | `servers/ut99/`   |
| UT2004 | 7797      | 7798, 10777 (LAN)     | 5081      | `servers/ut2004/` |

All UDP except the web admin (TCP). Host networking, so both servers show up in
the in-game LAN tab. The Fedora Workstation firewall zone already allows these ports.

Images (pulled from Docker Hub, nothing to build):

- [`lacledeslan/gamesvr-ut99-freeplay`](https://github.com/LacledesLAN/gamesvr-ut99-freeplay):
  UT99 with the OldUnreal 469e patch, bonus packs 1-4, ~50 extra maps, MapVote 3.04
  and the mutators Fatboy, Unlimited Ammo and Zoom InstaGib.
  Built on [`gamesvr-ut99`](https://github.com/LacledesLAN/gamesvr-ut99).
- [`lacledeslan/gamesvr-ut2004`](https://github.com/LacledesLAN/gamesvr-ut2004):
  UT2004 v3369 with the ECE bonus pack and Community Bonus Packs 1 and 2.
  Their `-freeplay` image only adds an ini, so this setup uses the base image
  and its own overrides.

```sh
cp .env.example .env             # once, then set the passwords in it
docker compose up -d             # pull + start both
docker compose up -d ut2004      # just one
docker compose logs -f ut99      # console output
docker compose restart ut99      # apply changed configs / new maps
docker compose pull && docker compose up -d   # update the images
docker compose down              # stop and remove
```

There is no interactive console. Admin from the game (below) or the web admin.

## Passwords

In `.env` (copy of `.env.example`, not in git):

```sh
ADMIN_PASSWORD=...   # web admin and in-game admin, empty = web admin off
GAME_PASSWORD=       # password to join, empty = open server
```

After changing it: `docker compose up -d` (recreates the containers).

## For players

**Client versions:** UT99 clients need patch 432 or newer, the
[OldUnreal 469e patch](https://github.com/OldUnreal/UnrealTournamentPatches/releases)
is recommended. UT2004 clients need v3369, which Steam, GOG and the patched DVD have.

Join through *Find Internet Games → LAN* (UT99) or *Server Browser → LAN* (UT2004),
or by IP: console `open <host-ip>:7777` (UT99) / `open <host-ip>:7797` (UT2004).

Maps a player doesn't have are downloaded from the server when they join.

**Map vote**

- UT99 (MapVote 3.04): when you join, a window asks you to pick a MapVote hotkey.
  The vote window opens at the end of each match, or any time with the hotkey
  (mid-game vote once 50% have voted). It has the maps of DM, TDM, CTF, DOM and
  LMS, so the vote can switch the game type too.
- UT2004 (built-in): the vote opens at the end of each match, mid-game through
  Esc → *Map Voting*. Game types: DM, InstaGib DM, TDM, CTF, InstaGib CTF, Vehicle CTF,
  Onslaught, Assault, Bombing Run, Double Domination, Invasion.

Both have kick votes (51%).

## Admins

- In game: console `adminlogin <ADMIN_PASSWORD>`, then e.g.
  `admin servertravel CTF-Face?Game=Botpack.CTFGame` (UT99),
  `admin servertravel CTF-FaceClassic?Game=XGame.xCTFGame` (UT2004),
  `admin kick <name>`.
  UT99 MapVote has an extra Admin tab in the vote window.
- Web admin: `http://<host>:5080/ServerAdmin` (UT99, user `admin`) and
  `http://<host>:5081/ServerAdmin` (UT2004, any user name). Change map, game type,
  mutators, bots, kick/ban.

Changes made in the web admin last until the container restarts. To keep them,
put them in `overrides.ini` or `docker-compose.yml`.

## Settings

The start settings are environment variables in `docker-compose.yml`:

| Variable        | What |
|-----------------|------|
| `PORT`          | game port, the server also uses PORT+1 |
| `WEBADMIN_PORT` | web admin port, only on when `ADMIN_PASSWORD` is set |
| `SERVER_NAME`   | name in the server browser |
| `MAP`           | start map, e.g. `DM-Deck16][`, `CTF-Face`, `DM-Rankin`, `ONS-Torlan` |
| `GAME`          | start game type, short name (see below) or the full class |
| `MUTATORS`      | comma-separated, e.g. `BDBMapVote304.BDBMapVote,Botpack.InstaGibDM` |
| `MAXPLAYERS`    | max players |
| `BOTS`          | bots fill the server up to this many players (0 = no bots). They only come while a human is on |
| `OPTIONS`       | more URL options, e.g. `TimeLimit=10?GoalScore=20` |

Game types (`GAME`):

| UT99 | Class | UT2004 | Class |
|------|-------|--------|-------|
| `dm`  | Botpack.DeathMatchPlus  | `dm`   | XGame.xDeathMatch |
| `tdm` | Botpack.TeamGamePlus    | `tdm`  | XGame.xTeamGame |
| `ctf` | Botpack.CTFGame         | `ctf`  | XGame.xCTFGame |
| `dom` | Botpack.Domination      | `vctf` | XGame.xVehicleCTFGame |
| `as`  | Botpack.Assault         | `ons`  | Onslaught.ONSOnslaughtGame |
| `lms` | Botpack.LastManStanding | `as`   | UT2k4Assault.ASGameInfo |
|       |                         | `br`   | XGame.xBombingRun |
|       |                         | `dom`  | XGame.xDoubleDom |
|       |                         | `inv`  | SkaarjPack.Invasion |
|       |                         | `lms`  | BonusPack.xLastManStandingGame |
|       |                         | `mut`  | BonusPack.xMutantGame |

Map name prefixes match: DM-, CTF-, DOM-, AS-, ONS-, VCTF-, BR-. Mutators that come
with the games: UT99 `Botpack.InstaGibDM`, `Botpack.LowGrav`, `Botpack.ChainsawArena`, ...;
UT2004 `XGame.MutInstaGib`, `UnrealGame.MutLowGrav`, `XGame.MutQuadJump`, `XGame.MutVampire`, ...
(list in the [UT2004 server setup docs](https://github.com/LacledesLAN/gamesvr-ut2004/blob/main/Documentation/ServerSetup.md#list-of-retail-mutators)).
Keep `BDBMapVote304.BDBMapVote` in the UT99 `MUTATORS`, otherwise there is no map vote.

### overrides.ini

Everything else is in `servers/<game>/overrides.ini`, which is merged into the
image's ini (`UnrealTournament.ini` / `UT2004.ini`) on every start. Only the
lines you want different go in there, by section:

```ini
[Botpack.DeathMatchPlus]
FragLimit=30            ; set a value
TimeLimit=15

[Engine.GameEngine]
+ServerPackages=MyMod   ; add the line if it's missing
-ServerPackages=Fatboy  ; remove that line
```

Several lines with the same key in one section replace the whole list (used for
`ServerActors` and the UT2004 vote `GameConfig` lines). Sections and keys are
not case-sensitive. The environment variables are applied after this file.

What the overrides change now: no master server uplinks, LAN broadcast on (off in
the UT2004 image), downloads straight from the server (UT99 image points to
Laclede's LAN's download server), higher download rate, frag/time limits, MOTD,
map vote setup.

To see a setting's current value and its section, look at the ini the server
runs with:

```sh
docker exec ut99 cat System/UnrealTournament.ini
docker exec ut2004 cat UT2004.ini
docker exec ut99 cat System/UnrealTournament.ini.stock   # the image's original
```

## Custom maps and mods

Put the files into `servers/<game>/content/`, in the same subdirectories as in
the game, then `docker compose restart <game>`:

| Files | UT99 | UT2004 |
|-------|------|--------|
| maps  | `Maps/*.unr` | `Maps/*.ut2` |
| textures | `Textures/*.utx` | `Textures/*.utx` |
| sounds / music | `Sounds/*.uax`, `Music/*.umx` | `Sounds/*.uax`, `Music/*.ogg` |
| static meshes / animations | | `StaticMeshes/*.usx`, `Animations/*.ukx` |
| code (mutators, game types) | `System/*.u`, `*.int` | `System/*.u`, `*.ucl`, `*.int` |

The content is copied over the game directory at start, so it can also replace
stock files. Files in `content/` are not in git. Map vote picks up new maps by their prefix. A mutator also needs to be
in `MUTATORS`, and if it has client-side parts its package has to be added as
`+ServerPackages=<Package>` in `[Engine.GameEngine]` of `overrides.ini` so clients
download it. `.umod` installers have to be unpacked first (e.g. install them into
a client and copy the files).

## Files

```
docker-compose.yml   both servers, start settings
.env.example         template for .env (ADMIN_PASSWORD, GAME_PASSWORD; .env is not in git)
scripts/
  ut99.sh            entrypoint UT99: builds the ini, starts ucc-bin
  ut2004.sh          entrypoint UT2004
  ini-patch.awk      merges overrides.ini into the stock ini
servers/ut99/
  overrides.ini      UT99 settings
  content/           custom Maps/, Textures/, Sounds/, Music/, System/
servers/ut2004/
  overrides.ini      UT2004 settings
  content/           custom Maps/, Textures/, StaticMeshes/, ... System/
```

Logs: `docker compose logs`. The server's own log and stats files stay in the
container (`/app/System/server.log`, `/app/Logs/`, `docker cp` to fetch them) and
are gone after `docker compose down`.

To run a second server of a game, copy its service in `docker-compose.yml`, give it
another `container_name`, `PORT` (+10 is enough), `WEBADMIN_PORT` and its own
`servers/<name>/` directory.
