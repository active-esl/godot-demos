# Can It Run Freedoom?

A touch-first Godot 3 concept for the Active-Edge PoE display platform. The
first vertical slice proves the product UX, software framebuffer, controls,
attract mode, export and enclosure integration without distributing any
proprietary Doom data.

## Current runtime

The checked-in runtime is a small original GDScript 2.5D raycaster. It is a
hardware and interaction proof, not the Doom engine and not the Freedoom game.
The UI is built from Godot `Control` nodes; the low-resolution game view is an
`ImageTexture` framebuffer.

The production integration seam is intentionally explicit:

- native target: a pinned GPL Doom-compatible engine consumes a pinned
  `freedoom2.wad`, writing into the same framebuffer/input boundary;
- web target: the pinned browser-compatible engine and Freedoom payload is now
  published at `/freedoom-engine/`, with touch, pen, mouse and keyboard input;
- no proprietary Doom WAD, logo, music or artwork enters this repository;
- engine source, build recipe, exact revision, checksum and licence notices
  ship beside every binary release.

## Controls

- Touch: directional pad, strafe, `FIRE`, `USE / OPEN`.
- Keyboard: arrows or WASD, Q/E to strafe, Space to fire.
- Attract mode resumes automatically on launch and can be re-enabled with the
  on-screen button.

## Smoke test

```sh
godot3 --path demos/freedoom-poe --no-window -s scripts/model_smoke.gd
godot3 --path demos/freedoom-poe --no-window -s scripts/ui_smoke.gd
```

## Licensing

The Godot vertical slice contains only original MIT-licensed project code. The
separate browser payload contains GPLv2 engine code and BSD-licensed Freedoom
data. Its exact revisions, checksums, rebuild recipe and notices live under
`third_party/freedoom-engine/` and ship beside the published payload.
