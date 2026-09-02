#!/bin/sh
set -eu

export XDG_RUNTIME_DIR=/run
export WAYLAND_DISPLAY=wayland-0
export SDL_VIDEODRIVER=wayland

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exec /usr/bin/godot3 --video-driver GLES2 --path "$project_dir"

