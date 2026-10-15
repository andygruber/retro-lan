# Counter-Strike 1.6 dedicated server (HLDS, Steam app 90) with
# ReHLDS, ReGameDLL, Metamod-R, AMX Mod X, ReAPI and plugins

ARG BASE_IMAGE=debian:trixie-slim

# ---------------------------------------------------------------------------
# Download addons and compile plugins
FROM ${BASE_IMAGE} AS addons

ARG DEBIAN_FRONTEND=noninteractive
ARG REHLDS_VERSION=3.15.0.896
ARG REGAMEDLL_VERSION=5.30.0.814
ARG METAMOD_VERSION=1.3.0.149
ARG REAPI_VERSION=5.29.0.358
ARG AMXX_VERSION=1.9.0.5303
ARG MAPMANAGER_VERSION=v3.2.0
ARG REDM_VERSION=1.0.0-b11
ARG REGG_VERSION=v.0.5.41-beta-release

# amxxpc is a 32-bit binary
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl unzip lib32gcc-s1 lib32stdc++6 lib32z1 \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN set -eux; \
    gh=https://github.com; \
    amxx_short=$(echo ${AMXX_VERSION} | sed -E 's/^([0-9]+\.[0-9]+\.[0-9]+)\.([0-9]+)$/\1-git\2/'); \
    curl -fsSL -o rehlds.zip    $gh/rehlds/ReHLDS/releases/download/${REHLDS_VERSION}/rehlds-bin-${REHLDS_VERSION}.zip; \
    curl -fsSL -o regamedll.zip $gh/rehlds/ReGameDLL_CS/releases/download/${REGAMEDLL_VERSION}/regamedll-bin-${REGAMEDLL_VERSION}.zip; \
    curl -fsSL -o metamod.zip   $gh/rehlds/Metamod-R/releases/download/${METAMOD_VERSION}/metamod-bin-${METAMOD_VERSION}.zip; \
    curl -fsSL -o reapi.zip     $gh/rehlds/ReAPI/releases/download/${REAPI_VERSION}/reapi-bin-${REAPI_VERSION}.zip; \
    curl -fsSL -o amxx-base.tgz $gh/alliedmodders/amxmodx/releases/download/${AMXX_VERSION}/amxmodx-${amxx_short}-base-linux.tar.gz; \
    curl -fsSL -o amxx-cs.tgz   $gh/alliedmodders/amxmodx/releases/download/${AMXX_VERSION}/amxmodx-${amxx_short}-cstrike-linux.tar.gz; \
    curl -fsSL -o mapmanager.zip $gh/Mistrick/MapManagerModular/releases/download/${MAPMANAGER_VERSION}/MapManager-${MAPMANAGER_VERSION}.zip; \
    curl -fsSL -o redm.zip      $gh/ReDeathmatch/ReDeathmatch_AMXX/releases/download/${REDM_VERSION}/ReDeathmatch-${REDM_VERSION}.zip; \
    curl -fsSL -o regg.zip      $gh/d3m37r4/regg/releases/download/${REGG_VERSION}/regg-${REGG_VERSION}.zip; \
    curl -fsSL -o zbot.zip      https://raw.githubusercontent.com/rehlds/ReGameDLL_CS/${REGAMEDLL_VERSION}/regamedll/extra/zBot/bot_profiles.zip

# out/ mirrors the hlds directory
RUN set -eux; \
    mkdir -p out/cstrike x; \
    # ReHLDS: engine + hlds_linux
    unzip -q rehlds.zip 'bin/linux32/*' -d x/rehlds; \
    cp -a x/rehlds/bin/linux32/. out/; \
    chmod +x out/hlds_linux out/hltv; \
    # ReGameDLL: game library (its game.cfg would override server.cfg values)
    unzip -q regamedll.zip 'bin/linux32/*' -d x/regamedll; \
    rm x/regamedll/bin/linux32/cstrike/game.cfg; \
    cp -a x/regamedll/bin/linux32/cstrike/. out/cstrike/; \
    # CS bots (zBot) built into ReGameDLL: profiles, chatter, radio sounds
    sed -i 's/^bot_enable .*/bot_enable "1"/' out/cstrike/game_init.cfg; \
    grep -q '^bot_enable "1"' out/cstrike/game_init.cfg; \
    unzip -q zbot.zip 'cstrike/*' -d out; \
    # Metamod-R
    unzip -q metamod.zip 'addons/*' -d out/cstrike; \
    echo 'linux addons/amxmodx/dlls/amxmodx_mm_i386.so' > out/cstrike/addons/metamod/plugins.ini; \
    # AMX Mod X + ReAPI module
    tar -xzf amxx-base.tgz -C out/cstrike; \
    tar -xzf amxx-cs.tgz -C out/cstrike; \
    unzip -q reapi.zip 'addons/*' -d out/cstrike; \
    printf '\nreapi\n' >> out/cstrike/addons/amxmodx/configs/modules.ini; \
    # MapManager, ReDeathmatch, ReGG. Their plugins-*.ini would load them on
    # every map; ReDM/ReGG are loaded per mode instead (configs/modes/*.ini)
    unzip -q mapmanager.zip -d x/mapmanager; \
    unzip -q redm.zip -d x/redm; \
    unzip -q regg.zip -d x/regg; \
    cp -a x/mapmanager/cstrike/. out/cstrike/; \
    cp -a x/redm/cstrike/. out/cstrike/; \
    cp -a x/regg/*/cstrike/. out/cstrike/; \
    rm out/cstrike/addons/amxmodx/configs/plugins-redm.ini out/cstrike/addons/amxmodx/configs/plugins-regg.ini; \
    # ReGG: use MapManager for the vote when someone wins
    sed -i 's/^regg_mapchange_type .*/regg_mapchange_type "1"/' out/cstrike/addons/amxmodx/configs/regg/regg-main.cfg; \
    rm -rf x

COPY plugins/ out/cstrike/addons/amxmodx/scripting/

# Compile everything from source with this AMXX version
RUN set -eux; \
    cd out/cstrike/addons/amxmodx/scripting; \
    for f in lan_*.sma map_manager_*.sma ReDeathmatch.sma redm_spawns.sma regg_*.sma; do \
      ./amxxpc "$f" -o"../plugins/${f%.sma}.amxx" > /tmp/amxxpc.log 2>&1 \
        || { cat /tmp/amxxpc.log; exit 1; }; \
      grep -i 'warning' /tmp/amxxpc.log || true; \
    done; \
    ls ../plugins

# ---------------------------------------------------------------------------
FROM ${BASE_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive
ARG UID=1000
ARG GID=1000

# HLDS and steamcmd are 32-bit binaries
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl lib32gcc-s1 lib32stdc++6 lib32z1 \
 && rm -rf /var/lib/apt/lists/*

RUN groupadd -g ${GID} steam && useradd -m -u ${UID} -g ${GID} -s /bin/bash steam

USER steam
WORKDIR /home/steam

RUN mkdir -p steamcmd \
 && curl -fsSL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
    | tar -xz -C steamcmd

# app_update 90 is notoriously flaky and often needs several passes until
# all files are present, so retry until hlds_linux and cstrike/ exist.
# ReHLDS needs the steam_api of the steam_legacy branch (current clients
# connect fine); the engine itself is replaced by ReHLDS below anyway.
RUN for i in 1 2 3 4 5; do \
      ./steamcmd/steamcmd.sh +force_install_dir /home/steam/hlds +login anonymous \
        +app_set_config 90 mod cstrike +app_update 90 -beta steam_legacy validate +quit; \
      [ -x hlds/hlds_linux ] && [ -f hlds/cstrike/liblist.gam ] && break; \
      echo "steamcmd pass $i incomplete, retrying"; \
    done \
 && [ -x hlds/hlds_linux ] && [ -f hlds/cstrike/liblist.gam ] \
 && mkdir -p .steam/sdk32 \
 && ln -s /home/steam/steamcmd/linux32/steamclient.so .steam/sdk32/steamclient.so \
 && rm -rf steamcmd/package/*.zip* .steam/logs

COPY --from=addons --chown=steam:steam /build/out/ /home/steam/hlds/

# load the game library through Metamod-R
RUN sed -i 's|^gamedll_linux .*|gamedll_linux "addons/metamod/metamod_i386.so"|' hlds/cstrike/liblist.gam \
 && grep -q metamod hlds/cstrike/liblist.gam

COPY --chown=steam:steam entrypoint.sh /home/steam/entrypoint.sh

WORKDIR /home/steam/hlds
ENV PORT=27015 MAP=de_dust2 MAXPLAYERS=16 MODE=classic MAPS=all
ENTRYPOINT ["/home/steam/entrypoint.sh"]
