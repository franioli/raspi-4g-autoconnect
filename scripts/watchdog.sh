#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACTIVATE_SCRIPT="${ACTIVATE_SCRIPT:-$SCRIPT_DIR/activate_4g.sh}"

UPLINK_IFACE="${UPLINK_IFACE:-usb0}"
PING_TARGET="${PING_TARGET:-www.google.com}"
PING_COUNT="${PING_COUNT:-1}"
PING_TIMEOUT="${PING_TIMEOUT:-5}"

export UPLINK_IFACE PING_TARGET PING_COUNT PING_TIMEOUT

log() {
  printf '[%s] %s\n' "$(date -Is)" "$*"
}

if "$ACTIVATE_SCRIPT" --check; then
  log "Connection on $UPLINK_IFACE is active."
  exit 0
fi

log "Connection on $UPLINK_IFACE is down; invoking activator."
if "$ACTIVATE_SCRIPT"; then
  log "Reactivation succeeded."
  exit 0
fi

log "Reactivation failed."
exit 1