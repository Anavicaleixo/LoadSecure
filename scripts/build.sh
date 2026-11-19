#!/bin/bash
set -e
/workspace/var/flutter-sdk/flutter/bin/flutter build web --release --no-web-resources-cdn --no-wasm-dry-run
rm -rf dist
mkdir -p dist/client dist/server
cp -a build/web/. dist/client/
cp server/index.js dist/server/index.js
