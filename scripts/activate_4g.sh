#!/bin/bash

# Activates the PDP context once the stable /dev/modem_at symlink appears.

AT_PORT="/dev/modem_at"
MAX_TRIES=15
COUNT=0

# Wait until the device file exists
while [ ! -e "$AT_PORT" ] && [ $COUNT -lt $MAX_TRIES ]; do
  sleep 2
  COUNT=$((COUNT + 1))
done

# If the device is found, send the activation command
if [ -e "$AT_PORT" ]; then
  echo "4G modem $AT_PORT found. Activating PDP context."
  # Issue the PDP activation command with carriage return.
  echo -e "AT+CGACT=1,1\r" > "$AT_PORT"
else
  echo "4G modem port $AT_PORT not found after multiple attempts. Check hardware."
  exit 1
fi