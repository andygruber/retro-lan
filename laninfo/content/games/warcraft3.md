---
title: Warcraft III
short: WC3
subtitle: Reign of Chaos + The Frozen Throne · Classic 1.29.2
summary: The real-time strategy classic incl. The Frozen Throne. Portable folder, just unpack and play over LAN. Up to 24 players.
genre: Real-time strategy
year: 2002
players: 2–24
platforms: [Windows, Linux]
tags: [rts, strategy, blizzard, dota, tower defense]
order: 30
color: "#1d4ed8"

downloads:
  - file: Warcraft 3 Classsic 1.29.2.zip
    label: Warcraft III 1.29.2 (ready to play)
    notes: Unpack and start, no installer. About 1.4 GB.
  - file: Warcraft 3 Classsic Keys.txt
    label: CD keys
    notes: Only needed if the game asks for one. Give every player a different key.
---

There is no dedicated server: one player creates the game, everyone else joins it. Everyone needs the same version (the 1.29.2 from here).

## Install

### Windows

1. Unpack the zip to e.g. `C:\Games`, you get `C:\Games\Warcraft III`. Avoid *Program Files*.
2. Start **`Warcraft III.exe`**. Don't use `Warcraft III Launcher.exe`, it only tries to reach Battle.net and update the game.
3. Optional: create a shortcut to `Warcraft III.exe` on the desktop.

### Linux

Runs well with Wine or Proton.

1. Unpack:

   ```sh
   unzip "Warcraft 3 Classsic 1.29.2.zip" -d ~/Games
   ```

2. Start it with Wine:

   ```sh
   cd ~/Games/"Warcraft III"
   wine "Warcraft III.exe"
   ```

   Or add `Warcraft III.exe` to Steam as a non-Steam game and force Proton (see [Help](/p/help)).

3. Black screen or graphics glitches? Add `-opengl` to the command (or the Steam launch options).

## Start options

Add these after the exe in a shortcut, e.g. `"Warcraft III.exe" -window`:

| Option | Effect |
|---|---|
| `-window` | Windowed mode |
| `-nativefullscr` | Fullscreen at the desktop resolution |
| `-classic` | Start *Reign of Chaos* instead of *The Frozen Throne* |
| `-opengl` | OpenGL instead of Direct3D (helps under Wine) |

## Play over LAN

1. Main menu → **Local Area Network**.
2. Pick a name, then **Create Game** (choose a map) or select an open game from the list and **Join Game**.
3. Allow `Warcraft III.exe` through the Windows firewall when asked (uses port 6112, TCP and UDP).

Custom maps (tower defense, DotA, …) are sent from the host to the other players automatically. Put new maps into the `Maps` folder of the game, or `Documents\Warcraft III\Maps`.

> [!TIP]
> Since 1.29 games can have up to 24 players, and the classic 12-player maps work as before.
