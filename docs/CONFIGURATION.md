# CONFIGURATION.md

# Configuration Instructions for Raspberry Pi 4G Autoconnect

This document provides detailed configuration instructions for the scripts and systemd service used to automatically connect to the 4G HAT (A7670E) on a Raspberry Pi. Follow the steps below to ensure proper setup and functionality.

## Prerequisites

- Ensure that the Raspberry Pi is running Raspberry Pi OS.
- The 4G HAT (A7670E) is properly connected and the SIM card is activated.
- The necessary scripts and systemd service files are in place as per the project structure.

## Script Configuration

### 1. `activate_4g.sh`

This script is responsible for activating the 4G modem. You may need to modify the following parameters:

- **AT_PORT**: Ensure this points to the correct device link for your modem (e.g., `/dev/modem_at`).
- **PDP Activation Command**: The command `AT+CGACT=1,1` is used to activate the PDP context. If your provider requires different commands, update this line accordingly.

### 2. `modem_bootstrap.sh`

This script initializes the modem and sets up the PPP connection. Configuration options include:

- **PPP Configuration**: Ensure that the PPP settings (e.g., `/etc/ppp/peers/provider`) are correctly configured for your network provider. This includes the APN, username, and password if required.

### 3. `watchdog.sh`

This script monitors the connection status. You can configure:

- **Ping Target**: Modify the target for the ping command to a reliable external server (e.g., `8.8.8.8` for Google DNS).
- **Check Interval**: Adjust the frequency of the checks by modifying the sleep duration in the script.

## Systemd Service Configuration

### `4g-modem-setup.service`

This service file ensures that the modem connection scripts are executed at boot. Key configurations include:

- **Dependencies**: The `Requires` and `After` directives should include any other services that need to be started before the modem setup.
- **Execution Order**: Ensure that the `ExecStart` command points to the correct script for activating the modem.

## Udev Rules Configuration

### `99-4g-hat.rules`

This file creates a persistent device link for the modem. Ensure that the following parameters are correctly set:

- **Vendor and Product IDs**: Replace the IDs in the rule with those specific to your modem. You can find these by running `lsusb` when the modem is connected.

## Final Steps

1. After making the necessary changes, reload the systemd configuration:
   ```bash
   sudo systemctl daemon-reload
   ```

2. Enable the service to start on boot:
   ```bash
   sudo systemctl enable 4g-modem-setup.service
   ```

3. Reboot the Raspberry Pi to apply all configurations:
   ```bash
   sudo reboot
   ```

4. Verify the connection status after rebooting to ensure everything is functioning correctly.

By following these configuration instructions, your Raspberry Pi should automatically attempt to connect to the 4G HAT on every boot, ensuring persistent internet connectivity.