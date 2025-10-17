#!/bin/bash

# watchdog.sh - Monitors the 4G connection and attempts to reconnect if lost.

AT_PORT="/dev/modem_at"
CHECK_INTERVAL=30  # Time in seconds between checks
MAX_RETRIES=5      # Maximum number of retries before giving up

function check_connection {
    # Check if the modem is connected by pinging a reliable address
    if ping -I usb0 -c 1 www.google.com &> /dev/null; then
        return 0  # Connection is active
    else
        return 1  # Connection is lost
    fi
}

function reconnect {
    echo "Connection lost. Attempting to reconnect..."
    for ((i=1; i<=MAX_RETRIES; i++)); do
        echo "Attempt $i of $MAX_RETRIES..."
        # Activate the PDP context
        echo -e "AT+CGACT=1,1\r" > "$AT_PORT"
        sleep 5  # Wait for a few seconds before checking again

        if check_connection; then
            echo "Reconnected successfully!"
            return 0
        fi
    done
    echo "Failed to reconnect after $MAX_RETRIES attempts."
    return 1
}

# Main loop to monitor the connection
while true; do
    if check_connection; then
        echo "Connection is active."
    else
        reconnect
    fi
    sleep $CHECK_INTERVAL
done