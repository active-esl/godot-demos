# Physical-screen Google Calendar bridge

The screen keeps its Google service-account credential locally and outside the
Godot export. A restricted systemd service fetches the room calendar and
atomically replaces `/var/lib/active-edge-room-booking/calendar_day.json` every
eight seconds. The native Godot application watches that file on the same
cadence and refreshes the room state and agenda without restarting.

## Provisioning outline

1. Install the CI-produced `active-edge-room-booking.pck` at
   `/opt/active-edge-room-booking/active-edge-room-booking.pck`. Do not copy
   the raw Godot source tree: the embedded `godot3-frt` package is a
   `tools=no` runtime and intentionally has no source-asset importer.
2. Install the calendar bridge under `/opt/active-edge-room-booking` and create
   its Python virtual environment from `scripts/requirements-gcal.txt`.
3. Create the locked-down `active-edge-room-booking` system user and group.
4. Materialise the existing service-account JSON as
   `/etc/active-edge-room-booking/gcal-sa.json`, owned by root and the service
   group with mode `0640`. Never put it in the repository or Godot PCK.
5. Install all three units from this directory. Enable
   `active-edge-room-calendar.timer` and `active-edge-room-booking.service`.
   The display service launches the PCK fullscreen in Weston and points it at
   `/var/lib/active-edge-room-booking/calendar_day.json`.

The default path already matches the systemd unit, so the launch environment is
only needed when a product image uses a different persistent-data directory.

For a bench demonstration, edit an event in the dedicated
`Active-ESL Room A (Demo)` Google calendar. The service fetches it on the next
timer tick and the running screen updates on its next eight-second check.

The key must be provisioned through the product image's secret-injection path
or directly from Bitwarden during controlled bench setup. It must not be baked
into a public image, update artefact, log, or support bundle.

## Embedded-runtime contract

CI imports source PNG/JPEG/WebP/SVG and font resources before producing the
PCK. The target runtime consumes those imported resources; it is not expected
to open the source assets directly. Runtime support required by this demo is:

- GLES2 through FRT/SDL2 and the Vivante driver;
- FreeType/dynamic fonts and imported texture resources;
- HTTP, TLS/CA certificates, JSON and atomic local-file reads;
- touch input and a 1280×800 fullscreen Weston surface;
- persistent `/var/lib/active-edge-room-booking` state;
- Python, timezone data, CA certificates and the pinned calendar dependencies
  for the separate Google Calendar bridge.

The service-account credential and live calendar snapshot are deliberately
outside the PCK. Never make either an exported Godot resource.
