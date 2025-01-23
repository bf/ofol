#!/bin/bash

./scripts/build.sh --bundle --debug-build -b tmp && ./tmp/ofol/bin/ofol ~/src/2024-better-forensics/

# meson setup --buildtype=release --prefix <prefix> build
# meson compile -C build
# DESTDIR="$(pwd)/lite-xl" meson install --skip-subprojects -C build