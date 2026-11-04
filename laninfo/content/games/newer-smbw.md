---
title: Newer Super Mario Bros. Wii
short: Newer
subtitle: Native PC port · andygruber's build · LAN co-op
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
    notes: Contains `windows/`, `linux/` and the already extracted game files in `game/` (Newer v1.30, USA). The PC port is the build from [andygruber's fork](https://github.com/andygruber/NSMB-Wii-Multiplayer-Recompilation).

links:
  - { label: "andygruber/NSMB-Wii-Multiplayer-Recompilation (this build)", url: "https://github.com/andygruber/NSMB-Wii-Multiplayer-Recompilation" }
  - { label: "WitherBlitz/NSMB-Wii-Multiplayer-Recompilation (original)", url: "https://github.com/WitherBlitz/NSMB-Wii-Multiplayer-Recompilation" }
  - { label: Newer Team, url: "https://newerteam.com/wii/" }
---

The PC port comes from [andygruber's fork](https://github.com/andygruber/NSMB-Wii-Multiplayer-Recompilation) of WitherBlitz's NSMB Wii recompilation. The zip has three folders: `windows`, `linux` and `game` (the game files). On the first start the program asks where the game files are: pick the `game` folder. It remembers the choice.

## Install

### Windows

1. Unpack `Newer Super Mario Bros Wii.zip`.
2. Start `NSMBW.exe` in the `windows` folder.
3. When it asks for the game folder, choose the `game` folder from the zip.

Saves and settings are in `Documents\MarioWiiSaveData`. To choose another game folder later, delete the `dvd_root` line in `Config.toml` there.

### Linux

```sh
unzip "Newer Super Mario Bros Wii.zip" -d ~/Games/newer
cd ~/Games/newer/linux
chmod +x NSMBW compat/NSMBW-compat
./NSMBW
```

When it asks for the game folder, choose `~/Games/newer/game`. The question comes as a dialog (zenity or kdialog, which normal desktops have).

Needs a Vulkan driver and glibc 2.35 or newer (Fedora 36+, Ubuntu 22.04+, Debian 12+, Arch, SteamOS). X11 and Wayland both work. If it says it found no Vulkan driver:

```sh
sudo dnf install mesa-vulkan-drivers vulkan-loader      # Fedora
sudo apt install mesa-vulkan-drivers libvulkan1         # Ubuntu, Debian
```

Saves and settings are in `~/.local/share/WiiCompiled`. To choose another game folder later, delete the `dvd_root` line in `Config.toml` there.

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
