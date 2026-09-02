# Active-Edge room booking

Touch-first Godot 3.6/GLES2 meeting-room panel concept for a 1280×800
embedded display. It demonstrates the complete scripted day-in-the-life flow
using fictional, deterministic data; it is not connected to a live calendar.

## Interaction

- `Next beat` advances through 08:55, 09:00, 09:40, 10:05 and 10:10.
- Check in, extend, end and walk-up booking actions update the shared agenda.
- `No-show` demonstrates automatic release of an unchecked meeting.
- `Offline` switches to the cached-agenda presentation.
- Free agenda rows can be tapped to create a 30-minute booking.
- Keyboard presentation shortcuts: `N`, `X`, `O`, `R`.

## Run

```sh
godot3 --video-driver GLES2 --path .
```

This is a host/web UI proof. It is not evidence of operation on an EVK or
production panel, and it does not claim certification by or live integration
with a third-party booking platform.

The in-product identity uses the approved Active-Edge horizontal lockup from
the canonical `marketing-collateral` brand library.
