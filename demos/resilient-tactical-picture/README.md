# Resilient Tactical Picture

A touch-first, QuadLoc-derived situational-awareness demonstration for the
Active-Edge Jaguar embedded display platform. It combines simulated personnel
tags, UWB/GNSS positioning confidence, ad-hoc mesh status, bearer degradation,
priority alerting, casualty evacuation and offline-to-online synchronisation.

The seven-beat deterministic story is suitable for a short customer demo:

1. Deploy a fictional five-person team.
2. Form the local mesh.
3. Degrade the primary communications bearer.
4. Continue tracking indoors without GNSS and show reduced confidence.
5. Receive a simulated man-down alert.
6. Assign an extraction point and share the route locally.
7. Restore the link and synchronise the complete incident record.

Tap personnel markers or team rows to inspect them. Use **Next event** and
**Previous** to run the story, **Reset** to return to the opening state, and
**FR/EN** to switch the complete interface between British English and French.
Keyboard equivalents are `N`/right, `P`/left, `R`, and `L`.

Automated review captures can select a deterministic state with
`TACTICAL_DEMO_PROFILE=uk|fr` and `TACTICAL_DEMO_BEAT=0..6`.

## Run

The project targets Godot 3.6, GLES2 and a 1920×1200 landscape display:

```sh
./run-demo.sh
```

Model smoke:

```sh
godot3 --video-driver GLES2 --path . --no-window -s scripts/model_smoke.gd
godot3 --video-driver GLES2 --path . --no-window -s scripts/ui_smoke.gd
```

## Demonstration and safety boundaries

- Every callsign, position, status and network event is fictional and simulated.
- The interface shows uncertainty explicitly rather than claiming false location
  precision.
- No real personnel data, frequencies, cryptographic material or operational
  procedures are included.
- References to bearers describe product behaviour conceptually, not a deployed
  military communications configuration.
- This software is a product demonstrator, not a certified safety system.

Code is MIT licensed under the repository licence. The bundled DejaVu fonts
retain their own licence in `fonts/LICENSE.txt`.
