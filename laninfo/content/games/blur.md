---
title: Blur
short: Blur
subtitle: Retail DVD (USA, EN/FR/DE/ES/IT) · patch 1.2
summary: Arcade racing with power-ups, Mario Kart style with real cars. Race over LAN with lots of players, or split screen on one PC.
genre: Racing
year: 2010
players: 2–20
platforms: [Windows, Linux]
tags: [racing, cars, arcade, power-ups, activision, bizarre creations]
order: 45
color: "#0284c7"

downloads:
  - file: Blur.zip
    label: DVD image + patch 1.2 + no-CD exe
    notes: "Contains the DVD as `.iso`, the 1.2 patch (`Blur_Patch_…_v12`) and a `Blur.exe` for version 1.2 that runs without the DVD. About 5.2 GB, plan ~15 GB free space."
---

Install from the DVD image, update to **1.2**, then replace `Blur.exe`. Everyone needs version 1.2 for LAN games. The game's online servers are gone, but **LAN** works.

## Install

### Windows

1. Unpack `Blur.zip`.
2. Double-click `Blur (USA) (En,Fr,De,Es,It).iso`. Windows mounts it as a DVD drive. Start `setup.exe` on it (or the autorun) and install Blur. It also offers DirectX, PhysX and the Visual C++ runtime; install them.
3. **Patch to 1.2.** Run `BizUpdaterPack.exe` from the `Blur_Patch_Win_EN-FR-DE-IT-ES_v12` folder.
   Manual way, if that doesn't work: open `Blur 1.2 Patch.zip` from the same folder and copy `gamedata.pak` and `gamedata.sig` into the `cache` folder of the Blur install folder, replacing the files.
4. **No DVD needed:** copy `Blur.exe` from `Blur_NoCD_Win_EN-FR-DE-IT-ES_for-version-12` into the Blur install folder and replace the existing one. Now you can eject the image (right-click the drive → *Eject*).
5. Start Blur from the Start Menu or desktop shortcut.

### Linux

Runs well with Wine or Proton.

1. Unpack, and unpack the DVD image too:

   ```sh
   unzip Blur.zip -d ~/Downloads/blur
   cd ~/Downloads/blur
   7z x "Blur (USA) (En,Fr,De,Es,It).iso" -oiso
   ```

2. Install in a Wine prefix, e.g. with **Lutris or Bottles** (*install from setup file*, pick `iso/setup.exe`), or with plain Wine:

   ```sh
   wine iso/setup.exe
   ```

3. **Patch to 1.2 (manual way):** unpack `Blur_Patch_Win_EN-FR-DE-IT-ES_v12/Blur 1.2 Patch.zip` and copy `gamedata.pak` and `gamedata.sig` into the `cache` folder of the Blur install folder (inside the Wine prefix under `drive_c`), replacing the files.
4. **No DVD needed:** copy `Blur_NoCD_Win_EN-FR-DE-IT-ES_for-version-12/Blur.exe` over the `Blur.exe` in the install folder.
5. Start `Blur.exe`. For Steam, add it as a non-Steam game and force a current Proton (see [Help](/p/help)).

## Play over LAN

1. Main menu → **Multiplayer** → **LAN**.
2. One player creates the game, the others join it from the list.
3. Allow `Blur.exe` through the Windows firewall when asked, otherwise nobody finds the game.

> [!TIP]
> On one PC, up to four players can race split screen. Gamepads are a must for that.
