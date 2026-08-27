#!/bin/bash
set -e

echo "Installing QuickNote Plugin..."

mkdir -p build 
cd build
cmake ..
cmake --build .
cd ..

echo "Copying QML and C++ plugin files to Omarchy plugins directory..."
LOCAL_PLUGIN_DIR="$HOME/.config/omarchy/plugins/my.quicknote"
mkdir -p "$LOCAL_PLUGIN_DIR/My/QuickNote"

cp -r plugin/* "$LOCAL_PLUGIN_DIR/"
cp build/libquicknoteplugin.so "$LOCAL_PLUGIN_DIR/My/QuickNote/"
cp build/qmldir "$LOCAL_PLUGIN_DIR/My/QuickNote/"

echo "Enabled my.quicknote"
omarchy plugin enable my.quicknote
omarchy restart shell

echo "Installation Finished!"
