# Active-Edge room booking

Touch-first Godot 3.6/GLES2 meeting-room panel concept for a 1280×800
embedded display. It demonstrates the complete scripted day-in-the-life flow
and can display the same Google Calendar room schedule used by the Zephyr room
panel demo.

On the published Pages build, GitHub Actions reads the dedicated
`Active-ESL Room A (Demo)` calendar using a service account and places a
privacy-minimised day snapshot into the Godot export. The browser receives no
Google credential, calendar identifier or original Google event identifier.
The deployment refreshes every five minutes and the panel clock advances from
real UTC time using the calendar's `Europe/London` offset.

## Interaction

- The default display uses live room time and selects the current or next event.
- `Next beat` switches to scripted demo time: 08:55, 09:00, 09:40, 10:05 and 10:10.
- Check in, extend, end and walk-up booking actions update the shared agenda.
- `No-show` demonstrates automatic release of an unchecked meeting.
- `Offline` switches to the cached-agenda presentation; `Reset` restores live time.
- Free agenda rows can be tapped to create a 30-minute booking.
- Keyboard presentation shortcuts: `N`, `X`, `O`, `R`.

## Run

```sh
godot3 --video-driver GLES2 --path .
```

This is a host/web UI proof. It is not evidence of operation on an EVK or
production panel, and it does not claim certification by or live integration
with a third-party booking platform.

Calendar events are read-only in the static Pages demonstration. Check-in,
extend, end and walk-up booking buttons are visibly labelled as local previews;
a server-side authenticated relay is required before those controls can safely
write back to Google Calendar.

## Calendar export

CI expects the service-account JSON in the repository secret
`AESL_ROOM_DISPLAY_GCAL_SA_JSON`. Without it (including untrusted pull requests),
the build uses the deterministic fixture:

```sh
python3.12 scripts/gcal_export.py \
  --fixture scripts/fixtures/google_events.json \
  --day 2026-09-02
```

Only the room-facing title and `Host:` line are published from this dedicated
demo calendar. Cancelled and all-day events are excluded, control characters
are removed, and Google event identifiers are replaced with short hashes.

The in-product identity uses the approved Active-Edge horizontal lockup from
the canonical `marketing-collateral` brand library.
