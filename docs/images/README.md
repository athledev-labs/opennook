# OpenNook screenshots

macOS app screenshots for the root `README.md`. Drop PNGs here with the
filenames below. Crop tightly to the opaque nook chrome only - no desktop
or browser background.

## Run the demo

From the repo root (after `swift build` once):

```sh
swift run Nook          # default demo - expanded home view
swift run ShelfNook     # file shelf (NookComponents)
```

Expand with **⌥⌘;** (Option + Command + semicolon), or hover the menu-bar
pill on the display where the nook appears.

Quit with **⌘Q** on the Nook process, or from the menu-bar item.

## Multi-display setup

OpenNook defaults to the **built-in (notched) display**. On a dual-monitor
setup the nook is on the laptop panel, not necessarily the screen you are
looking at.

For capture:

1. Glance at the built-in display (or mirror displays in System Settings).
2. Or open Settings -> Display in the nook and pick your external monitor
   or **Main display** for the session, then switch back when done.

Use a solid gray wallpaper and hide other windows (**Cmd+Option+H**) if
you want a clean backdrop behind the pill.

## Files to add

| Filename | What to capture |
| --- | --- |
| `nook-expanded.png` | Expanded demo home (`swift run Nook`) |
| `nook-shelf.png` | Shelf empty state (`swift run ShelfNook`) |

**Capture tip:** **Cmd+Shift+4**, then **Space**, click the nook window.
Or drag a tight region around the black pill only.

Recommended width: ~540 px (1x). PNG, no alpha required.
