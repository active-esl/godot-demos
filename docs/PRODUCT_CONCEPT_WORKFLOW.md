# Product concept Live UX workflow

This is the repeatable path from a product idea to a demonstrable embedded UX.
It keeps the application, enclosure presentation and hardware proof connected
without coupling their repositories or hiding platform defects in app code.

## Definition of done

1. **Product story** — name the audience, the three-minute story and the one
   interaction that proves the platform rather than merely decorating it.
2. **Demo boundary** — create one self-contained `demos/<slug>` Godot 3 project.
   UI uses `Control` nodes and containers; rendering content may use 2D/3D nodes
   or a documented framebuffer boundary.
3. **Input contract** — touch targets are at least 48 logical pixels, keyboard
   fallback is documented, gestures do not steal presses from Controls, and
   physical display/touch transforms remain BSP responsibilities.
4. **Idle story** — kiosk demos must become understandable without a presenter:
   provide an attract mode, visible status and a deterministic reset path.
5. **Portable payload** — keep target-specific engines behind a small action and
   framebuffer/data contract. Pin source revisions and checksums; never commit
   proprietary customer data or game assets.
6. **Proof gates** — add a headless model smoke, exported-pack smoke and browser
   load/input check. Test on the intended panel after web CI is green.
7. **Stable publication** — publish the standalone demo under its slug and copy
   JS/WASM/PCK to a stable `/embed/<slug>/godot.*` endpoint for product viewers.
   The consuming enclosure page must never depend on generated filenames.
8. **Enclosure twin** — reuse a versioned product GLB, map normalised screen UVs
   to the live app, arbitrate screen taps separately from orbit gestures, and
   assert a visible ready/input acknowledgement.
9. **Release evidence** — record commit IDs, licences, CI run, public URLs and
   target result in the release notes. Merge the producer before its consumer.

## Third-party engine/content gate

Before vendoring a runtime or asset, record its upstream URL, exact commit or
release, licence, source/build instructions, distributable artefacts and hash.
GPL binaries must ship with the corresponding-source route and notices. Doom
engine code does not grant rights to commercial Doom game data: this concept
uses Freedoom data only, and must not use Doom logos, music or WADs.
