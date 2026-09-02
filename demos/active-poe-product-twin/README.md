# Active POE interactive product twin

Godot 3.6/GLES2 vertical slice combining the lightweight Active POE mechanical
model with the real Active-Edge room-booking UX. The UX is rendered at
1280×800 into a `ViewportTexture` assigned to the model's `LCD` mesh.

## Interaction

- **Inspect product:** drag to orbit the enclosure.
- **Use display:** returns to a front-on product view and forwards pointer/touch
  events into the room-booking scene.

## i.MX8M Mini contract

- Godot 3.6 and GLES2 only; no Godot 4 renderer or GDExtension dependency.
- 31k-vertex look model rather than the detailed assembly model.
- No real-time shadows, HDR, screen-space effects, or compressed formats that
  require desktop S3TC/BPTC support.
- Embedded output is a PCK for the existing `godot3-frt` runtime and Vivante
  GLES2 driver.
- Target launch: `godot3 --main-pack active-poe-product-twin.pck --video-driver GLES2 --fullscreen`.
- Browser and target must be checked separately; browser input is not proof of
  SDL/FRT touchscreen delivery.

## Proof

```sh
godot3 --path . --no-window -s scripts/product_twin_smoke.gd
godot3 --path . --export-pack "Embedded PCK" dist/active-poe-product-twin.pck
godot3 --path . --export "Web" dist/index.html
```

On hardware, verify inspect drag, mode switching, room-booking tap, horizontal
swipe/scroll, and restart through the production Weston/FRT launch path.

The model is a texture-free runtime derivative of the canonical enclosure
STLs, with planar LCD UVs retained for the live viewport. It is intentionally
under 1 MB so each exported PCK is self-contained without shipping the large
branded splash texture. Refresh it deliberately from `display_shell_eth.stl`,
`display_glass_eth.stl`, and `display_accents_eth.stl` when the approved look
model changes; do not use the heavier assembly GLB for the embedded experience.
