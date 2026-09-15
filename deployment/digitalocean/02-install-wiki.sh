#!/bin/bash
# Install Federated Wiki, sessionless security plugin, and wiki-plugin-allyabase.
#
# wiki-plugin-allyabase must live inside wiki's own node_modules directory —
# Fedwiki discovers plugins by scanning that directory, not the global npm tree.

set -e

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

PLUGIN_REPO="https://github.com/freyja-love-and-magic/wiki-plugin-allyabase"
PLUGIN_TMP="/tmp/wiki-plugin-allyabase"

echo "Installing wiki and wiki-security-sessionless globally..."
npm install -g wiki wiki-security-sessionless

WIKI_NODE_MODULES="$(npm root -g)/wiki/node_modules"

echo "Cloning wiki-plugin-allyabase..."
rm -rf "$PLUGIN_TMP"
git clone --depth 1 "$PLUGIN_REPO" "$PLUGIN_TMP"

echo "Installing plugin dependencies..."
cd "$PLUGIN_TMP"
npm install

echo "Copying plugin into wiki's node_modules at $WIKI_NODE_MODULES..."
mkdir -p "$WIKI_NODE_MODULES/wiki-plugin-allyabase"
cp -r "$PLUGIN_TMP"/* "$WIKI_NODE_MODULES/wiki-plugin-allyabase/"

echo "wiki-plugin-allyabase installed."

# Make allyabase_setup.sh available from a stable path used by 03-install-services.sh
cp "$PLUGIN_TMP/allyabase_setup.sh" /usr/local/bin/allyabase-setup
chmod +x /usr/local/bin/allyabase-setup
