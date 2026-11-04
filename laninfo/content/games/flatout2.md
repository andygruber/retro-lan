---
title: FlatOut 2
short: FlatOut 2
subtitle: GOG offline installer · version 1.0
summary: Demolition derby racing with ragdoll drivers, destruction derbies and stunt mini games. Up to 8 players over LAN.
genre: Racing
year: 2006
players: 2–8
platforms: [Windows, Linux]
tags: [racing, cars, destruction, derby]
order: 40
color: "#ea580c"

downloads:
  - file: Flatout 2.zip
    label: GOG offline installer
    notes: Contains `setup_flatout_2_1.0_(26697).exe` and its `.bin` file. Keep both in the same folder.
---

One player creates the LAN game, everyone else joins. Everyone needs this version (GOG 1.0).

## Install

### Windows

1. Unpack `Flatout 2.zip`. You get two files: `setup_flatout_2_1.0_(26697).exe` and `setup_flatout_2_1.0_(26697)-1.bin`.
2. Double-click the `.exe` and follow the installer. Keep the `.bin` file next to it.
3. Start **FlatOut 2** from the Start Menu or desktop shortcut.

### Linux

Run the Windows installer with Wine/Proton:

- **Lutris, Bottles or Heroic:** add a new game, *install from setup file*, and pick `setup_flatout_2_1.0_(26697).exe`.
- **Plain Wine:**

  ```sh
  unzip "Flatout 2.zip" -d ~/Downloads/flatout2
  cd ~/Downloads/flatout2
  wine "setup_flatout_2_1.0_(26697).exe"
  ```

  Then start `FlatOut2.exe` from the install folder (inside the Wine prefix, by default `~/.wine/drive_c/GOG Games/FlatOut 2`).

- **Without installer:** `innoextract` unpacks GOG installers directly:

  ```sh
  innoextract -d ~/Games/FlatOut2 "setup_flatout_2_1.0_(26697).exe"
  ```

  Then add `FlatOut2.exe` from that folder to Steam as a non-Steam game with Proton (see [Help](/p/help)).

## Play over LAN

1. Main menu → **Multiplayer** → **LAN**.
2. The host picks **Create Game**, chooses the event type (race, derby, stunt) and tracks; everyone else selects the game from the list.
3. Allow `FlatOut2.exe` through the Windows firewall when asked, otherwise the game doesn't show up for others.

> [!TIP]
> A gamepad makes the game a lot more fun. Try the *Stunt* events (ragdoll long jump, bowling, darts) between races.
