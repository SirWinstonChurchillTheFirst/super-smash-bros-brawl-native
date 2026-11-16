# Super Smash Bros. Brawl – native PC version (Windows and Linux)

A native build of **Super Smash Bros. Brawl** for Windows and Linux PCs, made by static recompilation:
the game's PowerPC code is translated to C and compiled for your PC, so there is no emulator
and no PowerPC interpreter at run time. The Wii's hardware (graphics on Vulkan, sound, disc,
storage, controllers) is provided by the [wii-recomp runtime](https://github.com/SirWinstonChurchillTheFirst/wii-recomp).

> [!IMPORTANT]
> **No game code or data is in this repository or anywhere it downloads.** You need your own
> disc image of the game, dumped from your own disc. The translation runs on your PC.

## Status

Tested with **RSBP01** (Europe (PAL), revision 1).

Plays Events and Training fights (Battlefield, Delfino Plaza, Castle Siege) at 60 fps with fighters and stages drawn correctly. Tested on Windows 11 by playing into the first real scene; on the Linux mini PC through the menus. Nothing here says the game is playable to the end.

Only what is written here has been tested. It has not been played to the end. Other regions
or revisions may work but are untested.

Known limits of the runtime, for every game: the Wii Remote's speaker isn't played; real Wii
Remotes connect on Linux only (Windows uses keyboard, mouse and SDL3 controllers); on the
Linux mini PC, 2 of about 45 starts showed no picture and needed starting again.

## Benchmark

The same 90-second run on both machines: started from the disc, the same scripted inputs (the ones the tests use, through the intro and title into the menus), the first 15 s (start-up) left out, full screen, pictures at twice the Wii's resolution. The game caps itself at its own frame rate, so **Busy** (the share of each frame the game's code worked rather than waited) shows the headroom left.

| Machine | Average fps | 1 % low fps | Busy | Frames over 20 ms |
|---|---|---|---|---|
| High budget: Windows 11, Intel Core i7-13700KF, NVIDIA GeForce RTX 3070 Ti, 32 GB | 59.9 | 46.0 | 9.6 % | 0.11 % |
| Low budget: Batocera Linux mini PC (HP), AMD Ryzen 3 PRO 4350GE with Radeon Vega 6 graphics, 8 GB | 59.6 | 32.4 | 12.3 % | 0.39 % |

## Build and play

You need: your disc image (`.rvz`, `.iso`, `.wbfs`, `.wia`, `.gcz` or `.ciso`), a graphics card
with Vulkan, and a processor with AVX2 (Intel Haswell or AMD Zen and newer). The first build
takes a few minutes and needs about twice the disc image's size in free space.

**Windows 10/11 (x64)** – in PowerShell, in this folder:

```powershell
.\setup-windows.ps1 -Disc "D:\path\to\your\game.rvz"
.\play\Play.bat
```

It installs [MSYS2](https://www.msys2.org) with winget if it's missing (for the compiler), and
needs Python 3 and Git.

**Linux (x86-64)** – Debian/Ubuntu and relatives:

```bash
./setup-linux.sh /path/to/your/game.rvz
./play/play.sh
```

Playing again after more of the game has run? Run the setup again: the parts of the game that
ran are then compiled for speed.

## Controls

Keyboard, mouse and any controller SDL3 knows (Xbox, PlayStation, Switch Pro, …) work. The
defaults are written to `play/controllers.ini` on the first start, every setting explained.
**F11** (or Alt+Enter) switches to full screen; `WII_RECOMP_FULLSCREEN=1` starts in it.
Wii Remote held sideways (the default for Brawl's menus): arrow keys, 1 and 2; Nunchuk, Classic and GameCube controllers are set in controllers.ini.

## How it's made

- Runtime: [https://github.com/SirWinstonChurchillTheFirst/wii-recomp](https://github.com/SirWinstonChurchillTheFirst/wii-recomp) (branch `windows-port`, tested at
  `441bd724afc3`), a fork of [Zontex/wii-recomp](https://github.com/Zontex/wii-recomp) with
  Windows support and the fixes this game needed. GPL-3.0-or-later.
- Hardware behaviour follows [Dolphin](https://dolphin-emu.org) where noted in the runtime's
  CREDITS.md.

## AI usage

Disclosed openly: the Windows port of the runtime, the fixes this game needed and the scripts in
this repository were written with an AI coding assistant (Claude, by Anthropic) under the
author's direction, and tested by running the game on real hardware as described above. The
runtime it builds on, wii-recomp, is itself developed with AI assistance.

## Support

This is free and stays free, with no paid features. If you like it, you can support it with a
coffee – voluntary, nothing in return: **[ko-fi.com/krogger](https://ko-fi.com/krogger)** ☕

## License

The scripts in this repository are GPL-3.0-or-later. Super Smash Bros. Brawl is a trademark of Nintendo;
this project is not affiliated with or endorsed by Nintendo.
