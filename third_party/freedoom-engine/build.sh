#!/usr/bin/env bash
set -euo pipefail

engine_commit=51a7030bea563d96027301a36619c17347b9270d
freedoom_version=0.13.0
expected_zip=3f9b264f3e3ce503b4fb7f6bdcb1f419d93c7b546f4df3e874dd878db9688f59
expected_wad=7323bcc168c5a45ff10749b339960e98314740a734c30d4b9f3337001f9e703d
expected_wasm=84515cb0ad90e267dce597d83f14691f8f15549724a29baad052235332987254
script_dir="$(cd "$(dirname "$0")" && pwd)"
work_dir="${TMPDIR:-/tmp}/active-edge-freedoom-build"

mkdir -p "$work_dir"
curl --fail --location --retry 3 \
  "https://github.com/diekmann/wasm-fizzbuzz/archive/${engine_commit}.tar.gz" \
  -o "$work_dir/engine.tar.gz"
curl --fail --location --retry 3 \
  "https://github.com/freedoom/freedoom/releases/download/v${freedoom_version}/freedoom-${freedoom_version}.zip" \
  -o "$work_dir/freedoom-${freedoom_version}.zip"
echo "${expected_zip}  $work_dir/freedoom-${freedoom_version}.zip" | sha256sum --check --strict
rm -rf "$work_dir/source"
mkdir -p "$work_dir/source"
tar -xzf "$work_dir/engine.tar.gz" --strip-components=1 -C "$work_dir/source"
unzip -p "$work_dir/freedoom-${freedoom_version}.zip" "freedoom-${freedoom_version}/freedoom1.wad" > "$work_dir/source/doom/linuxdoom-1.10/doom1.wad"
echo "${expected_wad}  $work_dir/source/doom/linuxdoom-1.10/doom1.wad" | sha256sum --check --strict
git -C "$work_dir/source" apply "$script_dir/freedoom.patch"
docker run --rm -v "$work_dir/source:/src" -w /src/doom rust:1.81-bookworm bash -lc \
  'apt-get update && apt-get install -y --no-install-recommends clang-14 lld-14 llvm-14 binaryen make && ln -sf /usr/bin/llvm-ar-14 /usr/local/bin/llvm-ar-10 && ln -sf /usr/bin/llvm-ranlib-14 /usr/local/bin/llvm-ranlib-10 && make'
echo "${expected_wasm}  $work_dir/source/doom/doom.wasm" | sha256sum --check --strict
cp "$work_dir/source/doom/doom.wasm" "$script_dir/../../site/freedoom-engine/doom.wasm"
echo "Freedoom engine rebuilt and verified: ${expected_wasm}"
