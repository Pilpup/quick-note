#!/bin/bash
set -e

echo "Uninstalling..."

LOCAL_PLUGIN_DIR="$HOME/.config/omarchy/plugins/my.quicknote"

if [ -d "$LOCAL_PLUGIN_DIR" ]; then
    echo "Disabling my.quicknote..."
    omarchy plugin disable my.quicknote || true
    
    echo "Removing plugin files..."
    rm -rf "$LOCAL_PLUGIN_DIR"
    
    echo "Restarting Omarchy shell to apply changes..."
    omarchy restart shell
    
    echo "Bye Bye!"
else
    echo "QuickNote plugin is not installed in $LOCAL_PLUGIN_DIR."
fi
