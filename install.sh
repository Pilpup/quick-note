#!/bin/bash
set -e

echo "Installing QuickNote Plugin..."

mkdir -p build 
cd build
cmake ..
cmake --build .

echo "Need Permission to install the C++ module to Qt directory."
QT_QML_DIR=$(qmake6 -query QT_INSTALL_QML)

sudo mkdir -p "$QT_QML_DIR/My/QuickNote"
sudo cp libquicknoteplugin.so "$QT_QML_DIR/My/QuickNote/"
sudo cp qmldir "$QT_QML_DIR/My/QuickNote/"
cd ..

echo "Copying QML files to Omarchy plugins directory..."
mkdir -p ~/.config/omarchy/plugins/my.quicknote
cp -r plugin/* ~/.config/omarchy/plugins/my.quicknote/

echo "Enabled my.quicknote"
omarchy plugin enable my.quicknote
omarchy restart shell

echo "Installation Finished!"
