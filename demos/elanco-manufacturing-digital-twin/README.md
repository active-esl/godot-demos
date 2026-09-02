# Elanco manufacturing digital twin

Touch-first Godot 3.6/GLES2 concept for the Active ESL Jaguar Screen platform.
It presents simulated process, asset, quality and resource values for an
animal-health manufacturing scenario.

This is an unofficial concept demonstrator. Elanco and its marks belong to
Elanco or its affiliates; no endorsement, production connection or access to
Elanco systems is implied.

## Interaction

- Select an overview asset to open its detail view.
- Adjust the reactor temperature setpoint with the slider.
- Start or pause the simulated agitator.
- Use the bottom navigation or swipe horizontally between screens.

The application interface uses Godot `Control` nodes and container-managed
layout. It does not use canvas draw calls to construct UI chrome.

## Run

```sh
godot3 --video-driver GLES2 --path .
```

The design target is 1920×1200 landscape. Display orientation is supplied by
the BSP/compositor rather than application-specific rotation.
