#!/bin/bash
set -e
echo "Building QuickNote Plugin natively..."
mkdir -p build
cd build
cmake ..
cmake --build .
echo "Done! The plugin is ready in My/QuickNote/"
