#!/bin/sh
set -eu

export XDG_RUNTIME_DIR=/run
export WAYLAND_DISPLAY=wayland-0
export SDL_VIDEODRIVER=wayland

exec /usr/bin/godot3 --video-driver GLES2 --path /tmp/elanco-digital-twin
