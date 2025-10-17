#!/bin/bash
set -euo pipefail

AT_PORT="${AT_PORT:-/dev/modem_at}"
APN="${APN:-mobile.vodafone.it}"
DIAL_MODE="${DIAL_MODE:-0}"
USB_NET_MODE="${USB_NET_MODE:-0}"
MAX_TRIES=30
COUNT=0

send_at() {
  local cmd="$1"
  local pause="${2:-2}"
  echo ">> $cmd"
  printf '%s\r' "$cmd" > "$AT_PORT"
  sleep "$pause"
}

while [ ! -e "$AT_PORT" ] && [ $COUNT -lt $MAX_TRIES ]; do
  sleep 2
  COUNT=$((COUNT + 1))
done

if [ ! -e "$AT_PORT" ]; then
  echo "AT port $AT_PORT unavailable; ensure the modem is connected."
  exit 1
fi

echo "Provisioning modem on $AT_PORT with APN '$APN'."
send_at "AT"
send_at "AT+CPIN?"
send_at "AT+CGDCONT=1,\"IP\",\"$APN\""
send_at "AT+CGACT=1,1"
send_at "AT+DIALMODE=$DIAL_MODE"
send_at "AT\$MYCONFIG=\"usbnetmode\",$USB_NET_MODE" 5
echo "Provisioning complete; reboot or rerun activate_4g.sh to apply."