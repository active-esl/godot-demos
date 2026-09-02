# Active ESL Godot demos

[![Build and deploy Godot demos](https://github.com/active-esl/godot-demos/actions/workflows/pages.yml/badge.svg)](https://github.com/active-esl/godot-demos/actions/workflows/pages.yml)

Touch-first Godot demonstrations for Active ESL embedded display platforms.
This repository holds focused demos which can be built, tested and presented
independently while sharing a consistent engineering baseline.

## Demo catalogue

| Demo | Engine | Purpose | Try it |
|------|--------|---------|--------|
| [Active POE product twin](demos/active-poe-product-twin/) | Godot 3.6 / GLES2 | Interactive mechanical product with the real room-booking UX rendered on its display | Web demo after merge |
| [Elanco manufacturing digital twin](demos/elanco-manufacturing-digital-twin/) | Godot 3.6 / GLES2 | Simulated factory process, asset and quality views | [Web demo](https://active-esl.github.io/godot-demos/elanco-manufacturing-digital-twin/) |
| [Aero pressure digital twin](demos/aero-pressure-digital-twin/) | Godot 3.6 / GLES2 | Touch-orbitable single-seater, virtual airflow and simulated pressure telemetry | [Web demo](https://active-esl.github.io/godot-demos/aero-pressure-digital-twin/) |
| [Active-Edge room booking](demos/room-booking/) | Godot 3.6 / GLES2 | Meeting-room availability, agenda, check-in, extend and walk-up booking journey | [Web demo](https://active-esl.github.io/godot-demos/room-booking/) |
| [MAX Tablet](demos/resilient-tactical-picture/) | Godot 3.6 / GLES2 | Resilient network-node mapping, automatic route selection, degraded-path recovery and bilingual operation | [Web demo](https://active-esl.github.io/godot-demos/resilient-tactical-picture/) |

The Elanco-themed demonstrator uses simulated data and public themes. It is an
unofficial concept: it is not connected to an Elanco site or production system,
and no endorsement or access to Elanco systems is implied.

The aero demonstrator is deliberately customer-anonymous. Its procedural car,
pressure zones and values are fictional and do not reproduce any customer
vehicle, geometry, installation or dataset.

MAX Tablet uses fictional nodes, positions, routes and network events. It is a
product demonstrator rather than an operational or certified safety system,
and contains no real personnel or military data.

## Repository layout

```text
demos/
  <demo-name>/
    project.godot
    Main.tscn
    ...
.github/workflows/    build and publication automation
site/                  static catalogue landing page
dist/                 generated Pages output; never source
```

Each demo owns its Godot project, assets, export preset and local run script.
New demos use a stable lowercase slug, avoid dependencies on sibling projects,
and document their engine version, platform assumptions, interaction model and
licensing in their directory.

Shared code or assets should only be promoted into a top-level `shared/`
directory after at least two demos genuinely use them. This keeps demos easy to
copy, deploy and test independently without premature coupling.

## Current demos

The manufacturing digital twin provides:

1. A process overview for raw material, bioreactor and fill-and-finish assets.
2. Reactor detail with simulated live conditions, setpoint and agitator control.
3. Quality, yield, energy and water performance views.
4. Touch buttons and horizontal swipe navigation.

The aero pressure digital twin provides:

1. An orbitable procedural 3D single-seater in a virtual wind tunnel.
2. Animated flow streaks which respond to tunnel speed and vehicle position.
3. Eight simulated pressure zones informed by our high-rate distributed MEMS
   sensor work.
4. Touch controls for orbiting, viewpoints, wind speed and zone selection.

Its UI is built from Godot `Control` nodes, containers and standard interactive
controls. It targets a 1920×1200 landscape display; physical panel orientation
remains the responsibility of the BSP and compositor.

Run it locally with:

```sh
godot3 --video-driver GLES2 --path demos/elanco-manufacturing-digital-twin
```

## Adding a demo

1. Create `demos/<demo-name>/` as a self-contained Godot project.
2. Use `Control` nodes and container-based layout for application UI.
3. Add a headless parse/smoke check and an export preset appropriate to its
   target.
4. Add it to the catalogue and extend CI with a separate, clearly named job.
5. Cache pinned toolchains and templates on self-hosted runners, then measure a
   warm run to confirm the intended speed-up.
6. Publish web-capable demos at a stable path under the collection Pages site.

## CI and publication

The current workflow publishes the catalogue at the Pages root and exports each
Godot demo beneath its own stable sub-path. The pinned exporter and templates
are checksum-verified and cached on self-hosted runners. As more demos are added,
CI should build each affected demo independently and assemble their outputs into
one Pages artefact rather than coupling all projects into a single Godot export.

The room-booking export refreshes its read-only, privacy-minimised Google
Calendar snapshot every five minutes. Calendar credentials remain in GitHub
Actions and are never included in the downloadable web application.

The native screen build instead reads an eight-second local snapshot generated
by a restricted systemd service. Its Google credential is provisioned onto the
device separately from the Godot application and is never committed or packed.

The Active POE product twin deliberately uses the lightweight look mesh and
GLES2 feature set. CI emits the same project as a browser experience and as an
embedded PCK for the i.MX8M Mini `godot3-frt` runtime.

## Licensing

Demo code is MIT licensed unless a demo directory states otherwise. Bundled
third-party assets retain their own licences; see the licence files beside
those assets.
