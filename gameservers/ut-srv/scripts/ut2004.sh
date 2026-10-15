#!/bin/bash
# Entrypoint for the UT2004 server (image lacledeslan/gamesvr-ut2004)
set -e
cd /app/System
ini=UT2004.ini

# Keep the image's ini once, so every start begins from the stock config and
# changes made in the web admin don't pile up (they last until a restart)
[ -f "$ini.stock" ] || cp "$ini" "$ini.stock"

# Custom content (Maps/, Textures/, StaticMeshes/, System/, ...) over the stock files
[ -d /content ] && cp -rf /content/. /app/

game=${GAME:-dm}
case ${game,,} in
  dm)   game=XGame.xDeathMatch ;;
  tdm)  game=XGame.xTeamGame ;;
  ctf)  game=XGame.xCTFGame ;;
  vctf) game=XGame.xVehicleCTFGame ;;
  ons)  game=Onslaught.ONSOnslaughtGame ;;
  as)   game=UT2k4Assault.ASGameInfo ;;
  br)   game=XGame.xBombingRun ;;
  dom)  game=XGame.xDoubleDom ;;
  inv)  game=SkaarjPack.Invasion ;;
  lms)  game=BonusPack.xLastManStandingGame ;;
  mut)  game=BonusPack.xMutantGame ;;
esac

# Settings from the environment, applied after servers/ut2004/overrides.ini
env_ini=$(mktemp)
cat > "$env_ini" <<EOF
[URL]
Port=${PORT:-7797}

[Engine.GameReplicationInfo]
ServerName=${SERVER_NAME:-UT2004 LAN Server}
ShortName=${SERVER_NAME:-UT2004 LAN Server}

[Engine.AccessControl]
AdminPassword=${ADMIN_PASSWORD}
GamePassword=${GAME_PASSWORD}

[Engine.GameInfo]
MaxPlayers=${MAXPLAYERS:-16}

[UnrealGame.UnrealMPGameInfo]
MinPlayers=${BOTS:-0}

[UWeb.WebServer]
bEnabled=$([ -n "$ADMIN_PASSWORD" ] && echo True || echo False)
ListenPort=${WEBADMIN_PORT:-5081}
EOF

overrides=()
[ -f /server/overrides.ini ] && overrides+=(/server/overrides.ini)
awk -f /scripts/ini-patch.awk "${overrides[@]}" "$env_ini" "$ini.stock" > "$ini"
rm -f "$env_ini"
[ -n "$ADMIN_PASSWORD" ] || echo "ADMIN_PASSWORD not set: web admin disabled"

url="${MAP:-DM-Rankin}?Game=$game?MinPlayers=${BOTS:-0}"
[ -n "$MUTATORS" ] && url+="?Mutator=$MUTATORS"
[ -n "$OPTIONS" ] && url+="?${OPTIONS#\?}"

echo "Starting: $url on port ${PORT:-7797}"

exec ./ucc-bin server "$url" ini="$ini" log=server.log -nohomedir -lanplay "$@"
