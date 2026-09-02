# Aero pressure digital twin

An anonymous, touch-first motorsport aerodynamics demonstrator for Godot 3.6.
It combines an orbitable CC0 low-poly single-seater, animated wind-tunnel flow and
simulated distributed pressure telemetry.

The pressure concept is informed by Active-Edge's dual-channel BMP581 sensor
work: high-rate sampling, distributed sensor nodes and aggregated values. It
does not reproduce a customer installation, vehicle, geometry, dataset or
confidential system architecture. All values and vehicle geometry are
simulated for demonstration.

The generic racing-car model is by scaranto and is distributed under CC0; see
[`assets/LICENSE.md`](assets/LICENSE.md) for source, licence and checksum.

## Interaction

- Drag over the 3D scene to orbit the car.
- Tap the preset-view buttons to jump to side, front or top views.
- Adjust tunnel speed with the touch-sized slider.
- Toggle airflow and tap pressure-zone buttons to inspect simulated readings.

The UI uses Godot `Control` nodes. The bounded 3D visualisation loads the CC0
glTF model and reuses airflow meshes rather than allocating geometry each frame.

Run on the embedded target with `./run-demo.sh`, or locally with:

```sh
godot3 --video-driver GLES2 --path demos/aero-pressure-digital-twin
```
