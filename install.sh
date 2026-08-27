#!/bin/bash
set -e

echo "Installing QuickNote Plugin..."

mkdir -p build 
cd build
cmake ..
cmake --build .
cd ..

echo "Copying QML and C++ plugin files...."
LOCAL_PLUGIN_DIR="$HOME/.config/omarchy/plugins/my.quicknote"
mkdir -p "$LOCAL_PLUGIN_DIR/My/QuickNote"

echo "$PWD" > "$LOCAL_PLUGIN_DIR/.repo_path"
cp -r plugin/* "$LOCAL_PLUGIN_DIR/"
cp manifest.json "$LOCAL_PLUGIN_DIR/"
rm -f "$LOCAL_PLUGIN_DIR/My/QuickNote/libquicknoteplugin.so"
cp build/libquicknoteplugin.so "$LOCAL_PLUGIN_DIR/My/QuickNote/"
cp build/qmldir "$LOCAL_PLUGIN_DIR/My/QuickNote/"

echo "Enabled my.quicknote"
omarchy plugin enable my.quicknote
omarchy restart shell

echo "Done!"
