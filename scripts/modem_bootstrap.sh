#!/bin/bash

# modem_bootstrap.sh
# This script initializes the modem and sets up the PPP connection.

AT_PORT="/dev/modem_at"
PPP_INTERFACE="ppp0"
MAX_TRIES=15
COUNT=0

# Function to check if the modem is connected
check_modem_connection() {
  if ifconfig | grep -q "$PPP_INTERFACE"; then
    return 0  # Modem is connected
  else
    return 1  # Modem is not connected
  fi
}

# Function to initialize the modem
initialize_modem() {
  echo "Initializing modem..."
  
  # Wait until the device file exists
  while [ ! -e "$AT_PORT" ] && [ $COUNT -lt $MAX_TRIES ]; do
    sleep 2
    COUNT=$((COUNT + 1))
  done

  if [ -e "$AT_PORT" ]; then
    echo "4G modem $AT_PORT found. Activating PDP context."
    echo -e "AT+CGACT=1,1\r" > "$AT_PORT"
  else
    echo "4G modem port $AT_PORT not found after multiple attempts. Check hardware."
    exit 1
  fi
}

# Main script execution
if ! check_modem_connection; then
  initialize_modem
else
  echo "Modem is already connected."
fi