# Physical-screen Google Calendar bridge

The screen keeps its Google service-account credential locally and outside the
Godot export. A restricted systemd service fetches the room calendar and
atomically replaces `/var/lib/active-edge-room-booking/calendar_day.json` every
eight seconds. The native Godot application watches that file on the same
cadence and refreshes the room state and agenda without restarting.

## Provisioning outline

1. Install the repository at `/opt/active-edge-room-booking` and create its
   Python 3.12 virtual environment from `scripts/requirements-gcal.txt`.
2. Create the locked-down `active-edge-room-booking` system user and group.
3. Materialise the existing service-account JSON as
   `/etc/active-edge-room-booking/gcal-sa.json`, owned by root and the service
   group with mode `0640`. Never put it in the repository or Godot PCK.
4. Install the unit and timer from this directory, then enable the timer.
5. Launch the native Godot application with
   `AESL_ROOM_BOOKING_CALENDAR_PATH=/var/lib/active-edge-room-booking/calendar_day.json`.

The default path already matches the systemd unit, so the launch environment is
only needed when a product image uses a different persistent-data directory.

For a bench demonstration, edit an event in the dedicated
`Active-ESL Room A (Demo)` Google calendar. The service fetches it on the next
timer tick and the running screen updates on its next eight-second check.

The key must be provisioned through the product image's secret-injection path
or directly from Bitwarden during controlled bench setup. It must not be baked
into a public image, update artefact, log, or support bundle.
