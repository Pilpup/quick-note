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

python3 -c "
import os, sys
target = sys.argv[1]
parts = target.split('/')
current = '/' if target.startswith('/') else ''
for part in parts:
    if not part: continue
    current = os.path.join(current, part)
    if os.path.islink(current):
        sys.exit('Error: Symlink detected at ' + current)
    if not os.path.exists(current):
        os.mkdir(current, 0o700)
" "$LOCAL_PLUGIN_DIR/My/QuickNote"

echo "$PWD" > "$LOCAL_PLUGIN_DIR/.repo_path"
cp -r plugin "$LOCAL_PLUGIN_DIR/"
cp manifest.json "$LOCAL_PLUGIN_DIR/"
rm -f "$LOCAL_PLUGIN_DIR/My/QuickNote/libquicknoteplugin.so"
cp build/libquicknoteplugin.so "$LOCAL_PLUGIN_DIR/My/QuickNote/"
cp build/qmldir "$LOCAL_PLUGIN_DIR/My/QuickNote/"

echo "Enabled my.quicknote"
omarchy-shell shell rescanPlugins
omarchy plugin enable my.quicknote
omarchy restart shell

echo "Done!"
