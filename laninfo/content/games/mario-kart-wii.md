---
title: Mario Kart Wii
short: MKW
subtitle: Native PC port · andygruber's build · LAN multiplayer
summary: Mario Kart Wii running natively on Windows and Linux with LAN races built in. No server, no Wii, up to 12 players.
genre: Racing
year: 2008
players: 1–12
platforms: [Windows, Linux]
tags: [mario, kart, racing, wii, nintendo]
order: 65
color: "#dc2626"

downloads:
  - file: MarioKartWiiLAN-2026.11.05-windows-linux.zip
    label: Game + Windows and Linux versions
    notes: Version 2026.11.05, needs about 3 GB unpacked. Contains `windows/`, `linux/`, the already extracted game files in `game/` (PAL, RMCP01) and `UserData/`. Built from [andygruber/MarioKartWiicompiledLAN](https://github.com/andygruber/MarioKartWiicompiledLAN).

links:
  - { label: "andygruber/MarioKartWiicompiledLAN (this build)", url: "https://github.com/andygruber/MarioKartWiicompiledLAN" }
---

The PC port is WiiCompiled by patchzyy with the "MKW LAN multiplayer" mod (by Chadderz and MrBean35000vr, Luporion's v0.9-Luporion.2 fork) built in, from [andygruber's repository](https://github.com/andygruber/MarioKartWiicompiledLAN). The game files are already included, so there is nothing to set up: unpack, set your name, play.

> [!IMPORTANT]
> Everyone needs **the same version** (the date in the file name, here 2026.11.05), otherwise you won't see each other.

## What's in the zip

Everything is in one folder, `MarioKartWiiLAN`. Keep its subfolders together: the game reads from `game` and writes to `UserData`.

| Folder / file | What it is |
|---|---|
| `windows/` | `WiiCompiled.exe` (the game) and `LanPlayerSetup.exe` (player name) |
| `linux/` | `WiiCompiled` (the game) and `LanPlayerSetup` (player name) |
| `game/` | The game files (Mario Kart Wii PAL) |
| `UserData/` | Your settings (`Config.toml`), saves (NAND) and logs |
| `portable.txt` | Keeps saves and settings inside the folder. Don't delete it. |
| `README.txt` | The original instructions |

To move to a newer version later, copy your `UserData` folder into the new one.

## Install

### Windows

1. Unpack `MarioKartWiiLAN-2026.11.05-windows-linux.zip`, e.g. to `C:\Games`.
2. Open `MarioKartWiiLAN\windows` and start **`LanPlayerSetup.exe`**.
3. If SmartScreen warns about an unknown app: *More info* → *Run anyway*.
4. Enter your name, pick a face and a favorite color, then **Save and play**. The game starts.

Next time you can start `WiiCompiled.exe` directly, or `LanPlayerSetup.exe` again to change your name.

Needs Windows 10 or 11 (64-bit) and a graphics card with DirectX 12 or Vulkan.

### Linux

```sh
unzip MarioKartWiiLAN-2026.11.05-windows-linux.zip -d ~/Games
cd ~/Games/MarioKartWiiLAN/linux
./LanPlayerSetup
```

Enter your name, pick a face and a favorite color, then **Save and play**. Next time you can start `./WiiCompiled` directly. If the files lost their executable bit (unpacked with something other than `unzip`): `chmod +x WiiCompiled LanPlayerSetup`.

Needs glibc 2.35 or newer (Fedora 36+, Ubuntu 22.04+, Debian 12+, Arch, SteamOS) and a Vulkan driver. If the game finds none:

```sh
sudo dnf install mesa-vulkan-drivers vulkan-loader      # Fedora
sudo apt install mesa-vulkan-drivers libvulkan1         # Ubuntu, Debian
```

With NVIDIA, the NVIDIA driver already includes Vulkan.

> [!NOTE]
> Needs a 64-bit processor with AVX2 (2013 or newer: Intel Haswell, AMD Excavator, any Ryzen). There is no build for older CPUs.

## The first start

1. Create a license (save file).
2. When it asks for a Mii, choose the one **LanPlayerSetup made** (it has your name).
3. Done: from now on changing the name in LanPlayerSetup is enough, the license keeps that Mii.

> [!WARNING]
> Picked a guest Mii? Then everyone else sees you as "Player". Fix it in the license's settings with **Change Mii**.

## Controls

Press <kbd>F10</kbd> in the game for the settings bar: controller and keyboard mapping, resolution, FPS counter, volume and more. Changes are saved right away.

The game sees a **GameCube controller**, whatever you plug in:

| GameCube button | In the race | In menus |
|---|---|---|
| Control stick | Steer; up/down: throw items forward/back | Move |
| A | Accelerate | Select |
| B | Brake / reverse | Back |
| R | Hop / drift | |
| L | Use item | |
| Z | Look back | |
| D-pad | Tricks off ramps, wheelie on bikes (up) | Move |
| Start | Pause | |

### Gamepad (recommended)

An Xbox, PlayStation, Switch Pro or similar controller is the most fun. **Plug it in before starting the game**: it works right away, nothing to set up.

- <kbd>F10</kbd> → *Controller settings* → *Layout* picks which buttons sit where (*GameCube*, *Classic Controller Pro* or *PlayStation*), *Customize buttons* changes single buttons.
- Controllers with a motion sensor (PlayStation, Switch Pro) can do tricks by flicking the controller (*Shake to trick*). If you start the game from Steam, turn Steam Input off for it, or Steam hides the sensor.
- Real Wii Remotes can be paired over Bluetooth in the same place.

### Keyboard

Without a gamepad the default is WASD to steer, left mouse button to accelerate and <kbd>Space</kbd> to brake. For racing properly, this layout works better. Set it in <kbd>F10</kbd> → *Controller settings* → *Keyboard and mouse* → *Customize keys*: click a binding, then press the key.

| Key | GameCube | Does |
|---|---|---|
| <kbd>W</kbd> | A | Accelerate |
| <kbd>Space</kbd> | B | Brake / reverse |
| <kbd>N</kbd> | R | Hop / drift |
| <kbd>Left Shift</kbd> | L | Use item |
| <kbd>Q</kbd> | Z | Look back |
| <kbd>Enter</kbd> | Start | Pause |
| <kbd>A</kbd> / <kbd>D</kbd> | Control stick left / right | Steer |
| <kbd>U</kbd> / <kbd>H</kbd> | Control stick up / down | Lean forward / back, throw items forward / back |
| <kbd>I</kbd> | D-pad up | Up trick, wheelie |
| <kbd>K</kbd> | D-pad down | Down trick, cancel wheelie |
| <kbd>J</kbd> / <kbd>L</kbd> | D-pad left / right | Left / right trick |

> [!TIP]
> <kbd>A</kbd> or <kbd>D</kbd> together with <kbd>U</kbd> or <kbd>H</kbd> pushes the stick diagonally, which steers less: use it for a softer drift angle.

Already have this layout in Dolphin? *Import from Dolphin* in the same place reads `GCPadNew.ini`, check the result afterwards.

## Play over LAN

1. Start the game on every PC.
2. In the main menu choose **Nintendo WFC**. It is now *LAN Multiplayer*, only the friends section is there.
3. The friend list fills itself with every PC on the network that runs the game. One player **creates a room**, the others **join** it from the friend list.

Up to 12 players. Choosing character, kart and track has the usual 30 seconds. Standing around in the menus no longer disconnects you.

> [!TIP]
> Someone got disconnected? Everyone leaves the LAN menu and enters it again.

Rankings, ghost uploads and the Mario Kart Channel are turned off.

### Firewall

The PCs find each other with UDP broadcasts on ports 27900–27929, races use further UDP ports the game picks.

- **Windows:** when the firewall asks the first time, allow *WiiCompiled* on private networks, and set the party network to *Private* in the Windows network settings.
- **Linux:** allow UDP from the LAN, e.g. with firewalld put your network device in the home zone (`sudo firewall-cmd --zone=home --change-interface=<device>`), or with ufw `sudo ufw allow from 192.168.0.0/16`.
