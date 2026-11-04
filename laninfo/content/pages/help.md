---
title: Help
icon: help
order: 10
---

## I don't see the server / the other players' game

- Make sure you're on the party network (cable or the party Wi-Fi), not on your phone's hotspot.
- **Windows firewall:** *Windows Security → Firewall & network protection → Allow an app through firewall*. Find the game's `.exe` and tick **Private**. If it isn't listed, click *Allow another app…* and pick the `.exe` from the game folder.
- Check that your network is set to *Private*: *Settings → Network & internet → Ethernet / Wi-Fi → Network profile type*.
- Join by IP instead of the LAN list. The address of the dedicated servers is `{{server_ip}}`, see each game's page for the exact command.

## My download stopped

Downloads can be resumed. In the browser, open the downloads list (<kbd>Ctrl</kbd>+<kbd>J</kbd>) and click *Resume*. On the command line:

```sh
wget -c "http://{{host}}/files/<file name>"
```

## How do I unpack the files?

### Windows

- `.zip`: right-click → *Extract all…*
- `.7z`: Windows 11 opens it directly (right-click → *Extract all…*). On Windows 10 use [7-Zip](https://www.7-zip.org/).

Extract games to a folder like `C:\Games`, not to *Program Files*: older games want to write into their own folder.

### Linux

```sh
unzip "UT.zip" -d ~/Games/UT       # .zip
7z x "file.7z" -o"$HOME/Games"      # .7z (package p7zip / 7zip)
```

## Windows games on Linux

Most of the Windows-only games run with Wine or Proton:

- **Steam:** *Games → Add a Non-Steam Game to My Library…* → pick the game's `.exe` → *Properties → Compatibility → Force the use of a specific Steam Play compatibility tool* → a current Proton.
- **Lutris / Bottles / Heroic:** add the `.exe` as a locally installed game.
- **Plain Wine:** `wine Game.exe` in the game folder.

The game pages say where something extra is needed.
