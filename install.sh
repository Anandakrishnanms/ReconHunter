#!/bin/bash

echo "[+] Installing ReconHunter..."

# Make script executable
chmod +x reconhunter.sh

# Move to /usr/local/bin for global access
sudo cp reconhunter.sh /usr/local/bin/reconhunter

echo "[+] Installed successfully!"
echo "[+] Run using: reconhunter"
