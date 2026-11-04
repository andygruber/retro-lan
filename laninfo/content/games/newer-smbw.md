---
title: Newer Super Mario Bros. Wii
short: Newer
subtitle: Native PC port · version 0.3.1 · LAN co-op
summary: The fan-made Newer campaign as a native Windows/Linux recompilation with LAN co-op. Couch or LAN, up to 4 players.
genre: Platformer
year: 2013
players: 1–4
platforms: [Windows, Linux]
tags: [mario, platformer, co-op, wii, nintendo]
order: 60
color: "#16a34a"

downloads:
  - file: Newer Super Mario Bros Wii.zip
    label: Game + Windows and Linux versions
    notes: Contains `windows/`, `linux/` and the already extracted game files in `game/` (Newer v1.30, USA).

links:
  - { label: NSMB-Wii-Multiplayer-Recompilation, url: "https://github.com/WitherBlitz/NSMB-Wii-Multiplayer-Recompilation" }
  - { label: Newer Team, url: "https://newerteam.com/wii/" }
---

The zip has three folders: `windows`, `linux` and `game`. The program looks for a folder called `game` next to itself, so move `game` into the folder for your system.

## Install

### Windows

1. Unpack `Newer Super Mario Bros Wii.zip`.
2. Move the `game` folder **into** the `windows` folder, so `game` sits next to `NSMBW.exe`.
3. Start `NSMBW.exe`. If it asks for the game folder, pick that `game` folder.

Saves and settings are in `Documents\MarioWiiSaveData`.

### Linux

```sh
unzip "Newer Super Mario Bros Wii.zip" -d ~/Games/newer
cd ~/Games/newer
mv game linux/
cd linux
chmod +x NSMBW compat/NSMBW-compat
./NSMBW
```

Needs a Vulkan driver and glibc 2.35 or newer (Fedora 36+, Ubuntu 22.04+, Debian 12+, Arch, SteamOS). X11 and Wayland both work. If it says it found no Vulkan driver:

```sh
sudo dnf install mesa-vulkan-drivers vulkan-loader      # Fedora
sudo apt install mesa-vulkan-drivers libvulkan1         # Ubuntu, Debian
```

Saves and settings are in `~/.local/share/WiiCompiled`.

> [!NOTE]
> On processors without AVX2 (older than ~2013–2015) the game starts the `compat` build by itself. It plays LAN games with everyone else, so keep the `compat` folder.

## Controls

A Wii Remote held sideways:

| Key | Wii Remote |
|---|---|
| Arrow keys | Move (D-pad) |
| <kbd>X</kbd> or <kbd>Space</kbd> | 2 (jump), <kbd>Space</kbd> in the air spins |
| <kbd>Z</kbd> or <kbd>Left Shift</kbd> | 1 (run, fireball) |
| <kbd>C</kbd> or <kbd>Ctrl</kbd> | Shake (spin, pick up) |
| <kbd>Q</kbd> / <kbd>E</kbd> | Tilt left / right |
| <kbd>B</kbd> | A |
| <kbd>Enter</kbd> or <kbd>Esc</kbd> | + (pause) |
| <kbd>-</kbd> or <kbd>Tab</kbd> | − |
| <kbd>F10</kbd> | Settings bar |
| <kbd>F11</kbd> | Fullscreen on/off |

A gamepad also works as a sideways Wii Remote. Change keys on the save file screen: press <kbd>Up</kbd>, pick the gear at the top right, then the *Keybinds* tab.

## Play over LAN

1. On the save file screen press <kbd>Up</kbd> to reach the **Couch** button at the top right and switch it to **LAN**.
2. One player chooses **Create Room**, the others **Join**. PCs on the same network find each other's rooms by themselves.
3. Windows asks about the firewall the first time you host: allow it. On Linux, allow the game's UDP traffic if you run firewalld/ufw.

<kbd>F10</kbd> → *LAN Play* shows your addresses; you can add another PC by its address there if it isn't found.

> [!TIP]
> LAN games always run in 16:9, so everyone sees the same picture. Solo you can use *Match Screen Resolution* in the Video tab for ultrawide.
