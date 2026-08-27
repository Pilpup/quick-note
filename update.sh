#!/bin/bash

echo "Pulling latest updates..."
git pull

echo ""
echo "Installing..."
./install.sh

echo "Done!"
