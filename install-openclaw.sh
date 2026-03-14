#!/usr/bin/env bash
set -euo pipefail

# add yum update upgrade
sudo dnf update -y
sudo dnf upgrade -y

echo "==> Installing Node.js 22 and git..."
curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash -
sudo dnf install -y nodejs git

echo "==> Node version: $(node --version)"
echo "==> npm version: $(npm --version)"

echo "==> Installing OpenClaw..."
sudo npm install -g openclaw@latest

echo "==> Running onboard with daemon install..."
openclaw onboard --install-daemon

echo "==> Logging in to channels..."
openclaw channels login

echo "==> Starting gateway on port 18789..."
openclaw gateway --port 18789
