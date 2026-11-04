---
title: Motocross Madness 2
short: MCM2
subtitle: MCM2:Reborn v0.4.0.2 · andygruber's build
summary: Motocross Madness 2 rebuilt for today's PCs. Modern menus and HUD, widescreen, OpenGL, gamepads and LAN games with up to 30 riders.
genre: Racing
year: 2000
players: 2–30
platforms: [Windows, Linux]
tags: [racing, motocross, bikes, baja, supercross, reborn, recompile]
order: 55
color: "#b45309"

downloads:
  - file: MCM2 Reborn.zip
    label: MCM2:Reborn v0.4.0.2 (ready to play)
    notes: The game with MCM2:Reborn already installed. Unpack and start, about 1.2 GB unpacked.

links:
  - { label: "andygruber/MCM2Reborn (this build)", url: "https://github.com/andygruber/MCM2Reborn" }
  - { label: "Latest release", url: "https://github.com/andygruber/MCM2Reborn/releases/latest" }
  - { label: "xshxdex98/MCM2Reborn (original project)", url: "https://github.com/xshxdex98/MCM2Reborn" }
---

**MCM2:Reborn** is Motocross Madness 2 rebuilt from the original game, from [andygruber's fork](https://github.com/andygruber/MCM2Reborn). It has modern menus and a new HUD at your screen's resolution, an OpenGL renderer, frame-rate independent physics, up to 30 riders per race, and real gamepad support (Xbox, DualShock 4, DualSense).

The zip is a complete, ready-to-play folder. LAN games need no account and no DirectPlay.

## Install

### Windows

1. Unpack `MCM2 Reborn.zip` to e.g. `C:\Games\MCM2 Reborn`. Avoid *Program Files*, the game writes its settings into its own folder.
2. Start **`MCM2Reborn Launcher.exe`** in that folder. Started from inside the folder, it uses this copy directly.
3. The first time a short setup asks for picture quality, vsync, your controller and the look. Then press **PLAY**.

You can also start `MCM2Reborn.exe` directly to skip the launcher. When it has internet, the launcher also keeps MCM2:Reborn up to date.

### Linux

Runs with Wine or Proton. **GE-Proton** (the latest) is the one it's tested with.

1. Unpack:

   ```sh
   unzip "MCM2 Reborn.zip" -d ~/Games/"MCM2 Reborn"
   ```

2. **Steam:** *Games → Add a Non-Steam Game* → `MCM2Reborn Launcher.exe` from that folder. In its *Properties*, set *Compatibility* to GE-Proton and the *Launch Options* to `--play`. *Play* then goes straight into the game.
3. **Lutris:** *Add locally installed game*, runner *Wine*, *Executable* `MCM2Reborn Launcher.exe`, *Arguments* `--play`. Use a 64-bit prefix and a Wine with wine-mono (Wine-GE or a recent Wine).

> [!NOTE]
> The intro and menu videos only play if the launcher finds **ffmpeg** (it converts them once). Without ffmpeg they're skipped, the game is the same. Under Proton, put a Windows `ffmpeg.exe` next to the launcher.

## Settings

Everything is in the game's **Options**, under **REBORN** and **GAMEPAD**: widescreen menus, anti-aliasing, filtering, vsync, frame limit, FXAA, sharpening, bloom, number of riders, gamepad response and dead zone. The same settings are in `MCM2Reborn.ini` in the game folder. Any action can be bound to any button.

## Play over LAN

1. In the game open the **LAN** screen (or the *Local Network* tab of the *Internet* screen).
2. One player hosts and picks the event (Baja, Enduro, Nationals, Supercross) and track, the others join from the list.
3. Windows asks once to let **`mcm2-lan.exe`** through its firewall: allow it on private networks.

If you're missing the host's track or another rider's skins, the lobby offers to download them. Each rider's ping and a ready count show in the lobby.

> [!TIP]
> Your own skins: every `.tga` in the `RIDERS` and `BIKES` folders shows up as its own choice.
