---
# Template for a new game. Copy to <name>.md (the file name becomes the URL:
# games/<name>). Files starting with "_" are ignored. Everything except
# "title" is optional. {{server_ip}}, {{host}} and the vars from site.yml work
# everywhere in this file.

title: My Game
short: MG                     # text on the cover when there is no image
subtitle: Version / edition
summary: One or two sentences for the game card.
genre: Shooter
year: 2000
players: 2–16
platforms: [Windows, Linux]   # also used by the platform filter
tags: [fps]                   # extra search words
order: 100                    # sort order on the games page (low first)
color: "#2563eb"              # cover color
# image: mygame.jpg           # cover image from content/assets/
# hidden: true                # hide the game without deleting the file

downloads:                    # files from the downloads folder (GAMES_DIR)
  - file: MyGame.zip          # path relative to the downloads folder
    label: Installer
    notes: Markdown allowed, e.g. `code`.
    # platform: Windows

servers:
  - name: My Game Server
    address: "{{server_ip}}:1234"
    protocol: UDP
    join: "connect {{server_ip}}:1234"   # console command, gets a copy button
    notes: What runs there.

links:
  - { label: Homepage, url: "https://example.com" }
---

The text below the second "---" is markdown.

Headings named "Windows", "Linux", "macOS" or "Steam Deck" that follow each
other on the same level become tabs, the visitor's system is preselected:

## Install

### Windows

1. Unpack.
2. Start `MyGame.exe`.

### Linux

```sh
wine MyGame.exe
```

## Play over LAN

> [!TIP]
> Callouts: [!NOTE], [!TIP], [!IMPORTANT], [!WARNING], [!CAUTION].
