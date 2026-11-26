#!/usr/bin/env bash
# Theme-tinted logo above the Omarchy lock screen password field.
# Clones the built-in omarchy.lock plugin, generates a white-silhouette
# asset from your PNG, and patches LockView.qml to render it tinted
# with the active theme color.
#
# Usage: ./install.sh [path/to/your-logo.png]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# The shell IPC wrapper needs OMARCHY_PATH; SSH/TTY contexts don't have it.
export OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}"
LOGO_INPUT="${1:-$SCRIPT_DIR/assets/logo-tint.png}"
PLUGIN_ID="omarchy.lock"
PLUGIN_DIR="$HOME/.config/omarchy/plugins/${USER}.lock"
MARKER="User logo above the password field"
ANCHOR="The crossed-out icon has no meaning"

log()  { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

command -v omarchy >/dev/null || fail "omarchy not found — this script is for Omarchy systems only."
command -v magick  >/dev/null || fail "ImageMagick 7 not found — install with: sudo pacman -S imagemagick"
[[ -f $LOGO_INPUT ]] || fail "logo not found: $LOGO_INPUT"

# Wait for the running shell — right after a fresh boot the desktop (and its
# plugin catalog) may not be up yet, and cloning would fail with
# "unknown built-in plugin".
log "Waiting for omarchy-shell to be reachable..."
for _ in $(seq 1 60); do
  omarchy-shell lock status >/dev/null 2>&1 && shell_up=1 && break
  sleep 2
done
[[ ${shell_up:-0} == 1 ]] || fail "omarchy-shell did not come up within 120s — is a desktop session running?"

# 1. Clone the built-in lock plugin (skipped if it already exists).
if [[ -d $PLUGIN_DIR ]]; then
  log "Plugin already cloned: $PLUGIN_DIR"
else
  log "Cloning $PLUGIN_ID plugin..."
  omarchy plugin clone "$PLUGIN_ID"
fi

# 2. Generate the white-silhouette asset from the user's PNG.
log "Generating tint-ready silhouette from $(basename "$LOGO_INPUT")..."
mkdir -p "$PLUGIN_DIR/assets"
"$SCRIPT_DIR/scripts/generate-logo-mask.sh" "$LOGO_INPUT" "$PLUGIN_DIR/assets/logo-tint.png"

# 3. Patch LockView.qml (idempotent).
LOCK_QML="$PLUGIN_DIR/LockView.qml"
[[ -f $LOCK_QML ]] || fail "LockView.qml not found in $PLUGIN_DIR"

if grep -q "$MARKER" "$LOCK_QML"; then
  log "LockView.qml already contains the logo block — skipping patch."
else
  grep -q "$ANCHOR" "$LOCK_QML" || fail "Anchor comment not found in LockView.qml — Omarchy layout may have changed. Insert snippet/lock-logo-block.qml manually above the fingerprint-notice Text."
  cp "$LOCK_QML" "$LOCK_QML.bak.$(date +%Y%m%d-%H%M%S)"
  log "Patching LockView.qml..."
  awk -v snip="$(cat "$SCRIPT_DIR/snippet/lock-logo-block.qml")" '
    !done && /The crossed-out icon has no meaning/ { print snip "\n"; done=1 }
    { print }
  ' "$LOCK_QML" > "$LOCK_QML.new" && mv "$LOCK_QML.new" "$LOCK_QML"
fi

# 4. Restart the shell so the lock service picks up the clone.
log "Restarting omarchy-shell..."
omarchy restart shell

log "Done! Test with:  omarchy system lock"
log "Uninstall with:   omarchy plugin remove ${USER}.lock"
