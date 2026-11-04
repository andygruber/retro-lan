---
title: Need for Speed Underground 2
short: NFSU2
subtitle: UG2.net Edition by rohankar
summary: Street racing and tuning in Bayview. A ready-to-play folder with widescreen fix, HD reflections, extra options and the UG2.net mod pack.
genre: Racing
year: 2004
players: 2–4
platforms: [Windows, Linux]
tags: [racing, cars, tuning, nfs]
order: 50
color: "#0d9488"

downloads:
  - file: Need for Speed Underground 2 - ug2.net Edition.7z
    label: NFSU2 UG2.net Edition (ready to play)
    notes: A `.7z` archive, about 1.8 GB. See [Help](/p/help) for unpacking.
---

A ready-to-play folder, no installer. Everyone in a LAN race must use this same package. Included mods: widescreen fix (ThirteenAG), Extra Options, Unlimiter, HD reflections, ReShade, car sound tuner, stance and animation mods.

## Install

### Windows

1. Unpack the `.7z` to e.g. `C:\Games` (Windows 11: right-click → *Extract all…*; Windows 10: [7-Zip](https://www.7-zip.org/)). Avoid *Program Files*, the game saves into its own folder.
2. Start **`SPEED2.EXE`** in the folder `Need for Speed Underground 2`.
3. If the game misbehaves, `SafeMode.bat` starts it in safe mode.

> [!WARNING]
> Some virus scanners flag `dinput8.dll`. It is the mod loader that loads the widescreen fix and the other mods. Without it the game runs without the mods.

### Linux

Runs with Wine/Proton. The mod loader needs the DLL override `dinput8=n,b`.

1. Unpack:

   ```sh
   7z x "Need for Speed Underground 2 - ug2.net Edition.7z" -o"$HOME/Games"
   ```

2. **Steam (also Steam Deck):** add `SPEED2.EXE` as a non-Steam game, set compatibility to a current **GE-Proton** and put this into the launch options:

   ```
   WINEDLLOVERRIDES="dinput8=n,b" %command%
   ```

3. **Plain Wine:**

   ```sh
   cd ~/Games/"Need for Speed Underground 2"
   WINEDLLOVERRIDES="dinput8=n,b" wine SPEED2.EXE
   ```

## Controls

- The controls can be changed in-game (thanks to the widescreen fix). Check them once, the default layout isn't perfect.
- To quit the game with a gamepad, press **L3 and R3** (both sticks) together.

## Play over LAN

1. In the main menu go to the online part and choose **LAN**.
2. One player creates the game (the PC then runs the LAN server), the others pick it from the list.
3. Allow `SPEED2.EXE` through the Windows firewall when asked.
