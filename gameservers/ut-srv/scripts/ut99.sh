#!/bin/bash
# Entrypoint for the UT99 server (image lacledeslan/gamesvr-ut99-freeplay)
set -e
cd /app/System
ini=UnrealTournament.ini

# Keep the image's ini once, so every start begins from the stock config and
# changes made in the web admin don't pile up (they last until a restart)
[ -f "$ini.stock" ] || cp "$ini" "$ini.stock"

# Custom content (Maps/, Textures/, System/, ...) over the stock files
[ -d /content ] && cp -rf /content/. /app/

game=${GAME:-dm}
case ${game,,} in
  dm)  game=Botpack.DeathMatchPlus ;;
  tdm) game=Botpack.TeamGamePlus ;;
  ctf) game=Botpack.CTFGame ;;
  dom) game=Botpack.Domination ;;
  as)  game=Botpack.Assault ;;
  lms) game=Botpack.LastManStanding ;;
esac

# Settings from the environment, applied after servers/ut99/overrides.ini
env_ini=$(mktemp)
cat > "$env_ini" <<EOF
[URL]
Port=${PORT:-7777}

[Engine.GameReplicationInfo]
ServerName=${SERVER_NAME:-UT99 LAN Server}
ShortName=${SERVER_NAME:-UT99 LAN Server}

[Engine.GameInfo]
AdminPassword=${ADMIN_PASSWORD}
GamePassword=${GAME_PASSWORD}
MaxPlayers=${MAXPLAYERS:-16}

[UWeb.WebServer]
bEnabled=$([ -n "$ADMIN_PASSWORD" ] && echo True || echo False)
ListenPort=${WEBADMIN_PORT:-5080}

[UTServerAdmin.UTServerAdmin]
AdminUsername=admin
AdminPassword=${ADMIN_PASSWORD}
EOF
# Bots: MinPlayers of every game type
for g in DeathMatchPlus TeamGamePlus CTFGame Domination Assault LastManStanding; do
  printf '\n[Botpack.%s]\nMinPlayers=%s\n' "$g" "${BOTS:-0}" >> "$env_ini"
done

overrides=()
[ -f /server/overrides.ini ] && overrides+=(/server/overrides.ini)
awk -f /scripts/ini-patch.awk "${overrides[@]}" "$env_ini" "$ini.stock" > "$ini"
rm -f "$env_ini"
[ -n "$ADMIN_PASSWORD" ] || echo "ADMIN_PASSWORD not set: web admin disabled"

url="${MAP:-DM-Deck16][}?Game=$game"
[ -n "$MUTATORS" ] && url+="?Mutator=$MUTATORS"
[ -n "$OPTIONS" ] && url+="?${OPTIONS#\?}"

echo "Starting: $url on port ${PORT:-7777}"
export LD_LIBRARY_PATH=".:${LD_LIBRARY_PATH}"
exec ./ucc-bin server "$url" ini="$ini" log=server.log -nohomedir -lanplay "$@"
