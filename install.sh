#!/usr/bin/env bash
set -euo pipefail

# Ensure git is available
nix shell nixpkgs#git --command true

# Clone repo into /etc/nixos
sudo git clone https://github.com/<you>/<repo>.git /etc/nixos || true

# Rebuild with flake
cd /etc/nixos
sudo nixos-rebuild switch --flake .#$(hostname)
