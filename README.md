# Elanco manufacturing digital-twin concept

Touch-first Godot 3.6/GLES2 concept for the Jaguar Screen platform. It uses
simulated data and public Elanco themes; it is not connected to an Elanco site
or production system.

> Unofficial concept demonstrator created by Active Edge Solutions Ltd. Elanco
> and its marks belong to Elanco or its affiliates. No endorsement or access to
> Elanco production systems is implied.

## Views

1. Process overview: feed vessel, bioreactor, fill-and-finish line, animated
   flow, gauges and batch KPIs.
2. Asset detail: reactor animation, live trends, temperature setpoint and an
   agitator start/pause control.
3. Quality and resources: right-first-time, yield, energy, water, quality
   gates and an operational recommendation.

Swipe horizontally or touch the bottom navigation. On the overview, touch an
asset to open its detail. On the asset page, drag the setpoint or touch the
agitator control.

## Positioning

- All process values are explicitly simulated.
- The interface is Elanco-inspired rather than a claim to be an official
  Elanco application.
- The content reflects Elanco's public emphasis on animal-health manufacturing
  and quality, plus operational energy and water management.
- Native vector graphics keep the workload appropriate for the Vivante
  GC7000NanoUltra and avoid heavyweight 3D assets in the first prototype.

## Run

```sh
godot3 --video-driver GLES2 --path .
```

The project uses a 1920x1200 design canvas but scales from the actual viewport.
Physical panel orientation remains the responsibility of the BSP/compositor.

## Licensing

The demo code is MIT licensed. Bundled DejaVu fonts retain their own licence;
see `fonts/LICENSE.txt`.
