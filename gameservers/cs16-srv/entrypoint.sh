#!/bin/bash
set -e
cd /home/steam/hlds

# Started as root: make the bind-mounted dirs writable for steam, then
# re-run this script as steam. Docker creates a missing host dir (e.g.
# navs/ or logs/ after a fresh clone) as root, and the host user may have
# another UID than steam, so the server couldn't write navs and logs.
# logs/ is mounted as a whole so its subdirs are created here, not by
# Docker; hlds and AMXX write into them through symlinks.
if [ "$(id -u)" = 0 ]; then
  mountpoint -q /navs && chown -R steam:steam /navs
  if mountpoint -q /logs; then
    if [[ ! $NAME =~ ^[A-Za-z0-9_-]+$ ]]; then
      echo "NAME must be set to the server's name (letters, digits, _ -), not \"$NAME\"" >&2
      exit 1
    fi
    mkdir -p "/logs/$NAME/hlds" "/logs/$NAME/amxmodx"
    chown steam:steam /logs
    chown -R steam:steam "/logs/$NAME"
    rm -rf cstrike/logs cstrike/addons/amxmodx/logs
    ln -s "/logs/$NAME/hlds" cstrike/logs
    ln -s "/logs/$NAME/amxmodx" cstrike/addons/amxmodx/logs
  fi
  exec setpriv --reuid=steam --regid=steam --init-groups env HOME=/home/steam "$0" "$@"
fi
amxcfg=cstrike/addons/amxmodx/configs

# Copy the shared files, then this server's files (server.cfg, mapcycle.txt,
# maps/, sound/, addons/, ...) over the stock cstrike dir. Stock files stay,
# so overlay maps are additive.
for dir in /overlay-shared /overlay; do
  [ -d "$dir" ] && cp -rf "$dir/." cstrike/
done

# LAN or internet and join password (server.env). Written into the copied
# server.cfg, so they also hold when classic mode re-runs it every map.
SV_LAN=${SV_LAN:-1}
if [[ $SV_LAN != [01] ]]; then
  echo "SV_LAN must be 0 or 1, not \"$SV_LAN\"" >&2
  exit 1
fi
sed -i '/^[[:space:]]*sv_lan[[:space:]]/d' cstrike/server.cfg
echo "sv_lan $SV_LAN" >> cstrike/server.cfg
if [ -n "$SV_PASSWORD" ]; then
  if [[ $SV_PASSWORD == *'"'* ]]; then
    echo "SV_PASSWORD must not contain double quotes" >&2
    exit 1
  fi
  sed -i '/^[[:space:]]*sv_password[[:space:]]/d' cstrike/server.cfg
  printf 'sv_password "%s"\n' "$SV_PASSWORD" >> cstrike/server.cfg
fi
echo "Network: $([ "$SV_LAN" = 1 ] && echo LAN || echo internet)$([ -n "$SV_PASSWORD" ] && echo ', join password set')"

# FastDL (server.env): clients download custom maps, wads, sounds, ... over
# HTTP instead of the slow in-game transfer. Served on TCP with the same
# port number as the game (UDP). Only downloadable content from the overlays
# is served, never configs (rcon password, admins).
FASTDL=${FASTDL:-0}
if [[ $FASTDL != [01] ]]; then
  echo "FASTDL must be 0 or 1, not \"$FASTDL\"" >&2
  exit 1
fi
sed -i '/^[[:space:]]*sv_downloadurl[[:space:]]/d' cstrike/server.cfg
if [ "$FASTDL" = 1 ]; then
  host=${FASTDL_HOST:-$(hostname -I 2>/dev/null | awk '{print $1}')}
  if [ -z "$host" ] || [[ $host == *[\"/[:space:]]* ]]; then
    echo "FASTDL_HOST must be an IP or hostname, not \"$host\"" >&2
    exit 1
  fi
  [ -n "$FASTDL_HOST" ] || echo "FASTDL_HOST not set, using $host"
  fastdl=/home/steam/fastdl
  rm -rf "$fastdl" && mkdir -p "$fastdl"
  for dir in /overlay-shared /overlay; do
    [ -d "$dir" ] || continue
    (cd "$dir" && find . -path ./addons -prune -o -type f \
      \( -iname '*.bsp' -o -iname '*.wad' -o -iname '*.wav' -o -iname '*.mp3' \
         -o -iname '*.mdl' -o -iname '*.spr' -o -iname '*.tga' -o -iname '*.bmp' \
         -o -path './overviews/*.txt' \) -print0) |
    while IFS= read -r -d '' f; do
      mkdir -p "$fastdl/$(dirname "$f")"
      ln -f "cstrike/$f" "$fastdl/$f" 2>/dev/null || cp -f "cstrike/$f" "$fastdl/$f"
    done
  done
  busybox httpd -f -p "$PORT" -h "$fastdl" &
  echo "sv_downloadurl \"http://$host:$PORT/\"" >> cstrike/server.cfg
  echo "FastDL: http://$host:$PORT/ ($(find "$fastdl" -type f | wc -l) files)"
fi

# True if the map has textures that are not embedded in the .bsp. Only then
# hlds opens the wads the map lists (all of them, fatal error if one is
# missing). BSP v30: texture lump offset at byte 20; each miptex has its
# name (16), width, height and 4 data offsets, which are 0 when external.
external_textures() {
  local bsp=$1 lump n off mip
  read -r lump < <(od -An -tu4 -j 20 -N 4 "$bsp")
  read -r n < <(od -An -tu4 -j "$lump" -N 4 "$bsp")
  [ "${n:-0}" -gt 0 ] || return 1
  for off in $(od -An -tu4 -v -j $((lump + 4)) -N $((n * 4)) "$bsp"); do
    [ "$off" = 4294967295 ] && continue
    read -r mip < <(od -An -tu4 -j $((lump + off + 24)) -N 4 "$bsp")
    [ "$mip" = 0 ] && return 0
  done
  return 1
}

# A map is playable if its .bsp exists and, when it needs external
# textures, every .wad it lists is there
playable() {
  local bsp="cstrike/maps/$1.bsp" w missing=()
  if [ ! -f "$bsp" ]; then
    echo "Skipping map $1: not installed"
    return 1
  fi
  while read -r w; do
    w=${w//\\//}; w=${w##*/}
    [ -z "$w" ] || [ -f "cstrike/$w" ] || [ -f "valve/$w" ] || missing+=("$w")
  done < <(grep -aoE -m1 '"wad" "[^"]*"' "$bsp" | head -n1 | sed -E 's/^"wad" "//; s/"$//' | tr ';' '\n')
  if [ ${#missing[@]} -gt 0 ] && external_textures "$bsp"; then
    echo "Skipping map $1: missing ${missing[*]} (put it in servers/<name>/)"
    return 1
  fi
}

# Map list: the server's own mapcycle.txt if it has one, otherwise all
# installed maps of the kind given by MAPS:
#   stock  - maps that come with CS 1.6
#   custom - maps added in shared/maps/ and servers/<name>/maps/
#   all    - both
candidates() {
  if [ -f /overlay/mapcycle.txt ]; then
    echo "Using mapcycle.txt of this server" >&2
    while read -r m _; do
      m=${m%$'\r'}
      [[ -z $m || $m == //* || $m == \;* ]] || echo "$m"
    done < cstrike/mapcycle.txt
    return
  fi

  local custom
  custom=$(find /overlay-shared/maps /overlay/maps -maxdepth 1 -name '*.bsp' -printf '%f\n' 2>/dev/null | sed 's/\.bsp$//' | sort -u)
  echo "No mapcycle.txt for this server, using ${MAPS:-all} maps" >&2
  case ${MAPS:-all} in
    custom) echo "$custom" ;;
    stock)  find cstrike/maps -maxdepth 1 -name '*.bsp' -printf '%f\n' | sed 's/\.bsp$//' | sort | grep -vxF -f <(echo "$custom") ;;
    *)      find cstrike/maps -maxdepth 1 -name '*.bsp' -printf '%f\n' | sed 's/\.bsp$//' | sort ;;
  esac
}

maps=()
while read -r m; do
  [ -n "$m" ] && playable "$m" && maps+=("$m")
done < <(candidates)
[ ${#maps[@]} -gt 0 ] || maps=(de_dust2)
echo "Maps: ${maps[*]}"

# Only playable maps in the mapcycle, and in maps.ini where MapManager votes
# from, unless the server overlay brings its own maps.ini
printf '%s\n' "${maps[@]}" > cstrike/mapcycle.txt
if [ ! -f /overlay/addons/amxmodx/configs/maps.ini ]; then
  cp cstrike/mapcycle.txt "$amxcfg/maps.ini"
fi

# If the start map isn't playable (e.g. fun maps not added yet), use the
# first playable map from the mapcycle
if ! playable "$MAP" > /dev/null; then
  echo "Map $MAP not playable, starting on ${maps[0]}"
  MAP=${maps[0]}
fi

# Bot navigation meshes: the server generates maps/<map>.nav the first time
# bots play a map (~20 s). Link them to /navs so they survive the container;
# a .nav that comes with a map (overlay) is used as is.
if [ -d /navs ]; then
  for bsp in cstrike/maps/*.bsp; do
    nav=${bsp%.bsp}.nav
    [ -e "$nav" ] && [ ! -L "$nav" ] && continue
    ln -sfn "/navs/${nav##*/}" "$nav"
  done
fi

# AMX Mod X admins from CS_ADMINS (admins.env), appended to users.ini.
# Comma separated, each entry one of
#   name:password[:flags]  name + password (player: setinfo _pw "password")
#   name[::flags]          name only, no password
#   ip[:flags]             IP address
#   STEAM_0:1:2345[:flags] SteamID (only with SV_LAN=0, on a LAN everyone
#                          is STEAM_ID_LAN)
# flags default to all rights
if [ -n "$CS_ADMINS" ]; then
  users=$amxcfg/users.ini
  sed -i '/^; --- CS_ADMINS start/,/^; --- CS_ADMINS end/d' "$users"
  {
    echo "; --- CS_ADMINS start (generated from admins.env on every start)"
    IFS=',' read -ra entries <<< "$CS_ADMINS"
    for e in "${entries[@]}"; do
      e=$(sed 's/^[[:space:]]*//; s/[[:space:]]*$//' <<< "$e")
      [ -n "$e" ] || continue
      if [[ $e == *'"'* ]]; then
        echo "Skipping admin entry with a quote: $e" >&2
        continue
      fi
      if [[ $e =~ ^(STEAM_[0-9]:[0-9]:[0-9]+)(:(.*))?$ ]]; then
        printf '"%s" "" "%s" "ce"\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[3]:-abcdefghijklmnopqrstu}"
        echo "Admin: ${BASH_REMATCH[1]}" >&2
        continue
      fi
      IFS=':' read -r who pw flags <<< "$e"
      if [[ $who =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
        # second field is the flags for an IP
        printf '"%s" "" "%s" "de"\n' "$who" "${pw:-abcdefghijklmnopqrstu}"
        echo "Admin: IP $who" >&2
      elif [ -n "$pw" ]; then
        printf '"%s" "%s" "%s" "a"\n' "$who" "$pw" "${flags:-abcdefghijklmnopqrstu}"
        echo "Admin: $who (with password)" >&2
      else
        printf '"%s" "" "%s" "e"\n' "$who" "${flags:-abcdefghijklmnopqrstu}"
        echo "Admin: $who (name only, no password)" >&2
      fi
    done
    echo "; --- CS_ADMINS end"
  } >> "$users"
fi

# Start mode for lan_modes.amxx; can be switched in game with /mode, /votemode
if [ ! -f "$amxcfg/modes/$MODE.ini" ]; then
  echo "Mode $MODE not found in $amxcfg/modes/, using classic"
  MODE=classic
fi
cp "$amxcfg/modes/$MODE.ini" "$amxcfg/plugins-mode.ini" 2>/dev/null || : > "$amxcfg/plugins-mode.ini"
echo "$MODE" > cstrike/addons/amxmodx/data/lan_mode.txt
echo "Starting in mode $MODE"

export LD_LIBRARY_PATH=".:${LD_LIBRARY_PATH}"
exec ./hlds_linux -game cstrike -console -port "$PORT" -pingboost 2 \
  +sv_lan "$SV_LAN" +maxplayers "$MAXPLAYERS" +map "$MAP" "$@"
