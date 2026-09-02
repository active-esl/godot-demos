#!/bin/sh
set -eu
cd "$(dirname "$0")"
exec godot3 --video-driver GLES2 --path .

