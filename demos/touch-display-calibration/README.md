# Touch and display calibration lab

A Godot 3.6/GLES2 diagnostic for bringing up embedded display products. It
tests the complete human-visible contract rather than compensating inside a
single application.

## Workflow

1. Use **Display** to verify orientation, mirroring, overscan, aspect ratio,
   RGB order and tonal range.
2. Use **Guided touch** to press five known targets. The demo compares rendered
   and reported coordinates across all axis inversion/swap combinations.
3. Use **Live input** to verify contact IDs, edge reach, drag continuity and
   two-contact pinch delivery.
4. Use **Results** to obtain the preferred generic Linux Device Tree properties
   and, optionally, copy a libinput udev rule for hot validation.

## Correction hierarchy

- Fixed panel mounting and discrete axis orientation belong in the touchscreen
  Device Tree node using `touchscreen-inverted-x`, `touchscreen-inverted-y`
  and/or `touchscreen-swapped-x-y`.
- Incorrect raw ranges, non-linearity or controller-specific reporting require
  driver, firmware, electrical or `touchscreen-size-*` investigation.
- A libinput matrix is a useful compositor-level validation/fallback when the
  kernel coordinates are correct but surface mapping is not.
- Application transforms are deliberately not generated. Godot, Qt and Flutter
  should consume the same correct BSP coordinate space.

All UI chrome uses Godot Control nodes. Custom drawing is confined to the
non-interactive diagnostic visualization surface.
