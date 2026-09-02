#!/usr/bin/env sh
set -eu
exec godot3 --video-driver GLES2 --path "$(dirname "$0")"

