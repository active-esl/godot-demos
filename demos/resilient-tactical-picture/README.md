# MAX Tablet

**MAX Tablet** is a touch-first resilient network-routing demonstration for the
Active-Edge Jaguar embedded display platform. It maps fictional heterogeneous
network nodes, calculates a path between two selected endpoints and visibly
reroutes traffic as links degrade or a relay disappears.

The deterministic seven-beat story is designed for a short review with Max:

1. Discover five fictional network nodes.
2. Calculate the lowest-cost route from HQ-7 to TEAM-ALPHA.
3. Detect a degraded link and reroute automatically.
4. Lose RELAY-2 while maintaining a path through VEHICLE-4.
5. Fall back to a constrained direct UHF path.
6. Show local store-and-forward readiness.
7. Restore and optimise the primary route.

Tap any map node or node-list row to make it the route source, then tap a
different node to choose the destination. Use **Next event** and **Previous** to
run the story, **Reset** to return to the opening state, and **FR/EN** to switch
the complete interface between British English and French. Keyboard equivalents
are `N`/right, `P`/left, `R`, and `L`.

## First-cut assumptions for Max review

These are design hypotheses, not confirmed customer requirements:

- “Route” means a communications/data path between network nodes, not personnel
  navigation or vehicle route planning.
- The useful first picture combines a geographic backdrop with a network
  topology overlay.
- The five node types are fictional examples: command post, fixed/portable
  relays, vehicle gateway and dismounted team.
- The tablet automatically chooses a weighted lowest-cost available path and
  makes degraded and offline links unambiguous.
- Cost, latency, quality, battery values and bearer labels are illustrative demo
  data, not measurements or a proposed radio configuration.
- The demo contains no real network protocol, radio integration, encryption,
  key management or military data.
- No STANAG, MIL-STD, DEF STAN or French defence-standard compliance is claimed.
  The visual language is deliberately generic pending Max’s review.

After Max has seen this cut, the outstanding questions are the intended meaning
of routing, actual node and bearer types, route-selection priorities, data
sources, interoperability standards, security domain, offline behaviour and
the target operational workflow. Those questions remain tracked separately so
the first conversation can be grounded in something concrete.

## Display and mobile behaviour

MAX Tablet defaults explicitly to landscape and opens at 1920×1200. This does
not depend on an accelerometer: the embedded Linux display stack and launcher
present a fixed landscape output. Browser touch and native touchscreen input
are both supported.

The same scene remains responsive in portrait for web previews or a deliberately
rotated display configuration. Portrait stacks the map above the operational
panel. On narrow phones, secondary summary, clock and node-list detail collapse
so the map, selected-node state, route status and touch navigation remain usable
without horizontal scrolling.

Automated review captures can select deterministic state with
`TACTICAL_DEMO_PROFILE=uk|fr` and `TACTICAL_DEMO_BEAT=0..6`.

## Run and test

The project targets Godot 3.6 and GLES2:

```sh
./run-demo.sh
godot3 --video-driver GLES2 --path . --no-window -s scripts/model_smoke.gd
godot3 --video-driver GLES2 --path . --no-window -s scripts/ui_smoke.gd
```

## Demonstration and safety boundaries

- Every node, position, route, status and network event is fictional and
  simulated.
- Degraded, constrained and offline states are shown explicitly.
- No real personnel data, frequencies, cryptographic material or operational
  procedures are included.
- This software is a product demonstrator, not an operational or certified
  safety system.

Code is MIT licensed under the repository licence. The bundled DejaVu fonts
retain their own licence in `fonts/LICENSE.txt`.
