#!/bin/bash

./scripts/build.sh && ./build-x86_64-linux/ofol/bin/ofol

# meson setup --buildtype=release --prefix <prefix> build
# meson compile -C build
# DESTDIR="$(pwd)/lite-xl" meson install --skip-subprojects -C build