# Reproducible Freedoom browser engine

The published `site/freedoom-engine/doom.wasm` is a pinned rebuild of the GPL
Linux Doom port in `wasm-fizzbuzz`, with the proprietary shareware WAD replaced
by the open Freedoom Phase 1 WAD.

Run `./build.sh` from this directory. It downloads only the two pinned source
archives, verifies the game-data checksum, applies `freedoom.patch`, and builds
inside the pinned `rust:1.81-bookworm` container. The output checksum must match
`checksums.sha256` before it is copied into the Pages payload.

The binary is checked in so normal Godot CI remains fast. Rebuilds are required
only when one of the pinned inputs or the toolchain changes.

This browser runtime is the product-shell integration proof. The Godot 3 native
target uses the same engine/content boundary through a native WASM host; HTML5
cannot load Godot GDNative modules, so the browser payload is served beside the
Godot export rather than pretending to execute inside it.
