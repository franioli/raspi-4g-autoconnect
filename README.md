# Raspberry Pi 4G Autoconnect

This project provides a set of scripts and configurations to enable automatic connection to a 4G modem (A7670E) on a Raspberry Pi. The scripts ensure that the modem is activated, the connection is established, and that the connection is monitored for reliability.

## Table of Contents

- [Raspberry Pi 4G Autoconnect](#raspberry-pi-4g-autoconnect)
  - [Table of Contents](#table-of-contents)
  - [Project Structure](#project-structure)
  - [Prerequisites](#prerequisites)
  - [Setup Instructions](#setup-instructions)
  - [Configuration](#configuration)
    - [Modem Activation (`activate_4g.sh`)](#modem-activation-activate_4gsh)
    - [Modem setup (`modem_setup.sh`)](#modem-setup-modem_setupsh)
    - [Connection Health Checks](#connection-health-checks)
    - [Systemd Service (`systemd/4g-modem-setup.service`)](#systemd-service-systemd4g-modem-setupservice)
    - [Udev Rule (`udev/99-4g-hat.rules`)](#udev-rule-udev99-4g-hatrules)
    - [Final Checks](#final-checks)
  - [Usage](#usage)
  - [Optional Cron Watchdog](#optional-cron-watchdog)

## Project Structure

The project consists of the following components:

- **scripts/**: Contains the main scripts for modem activation and connection management.

  - **activate_4g.sh**: Activates the 4G modem by sending AT commands to establish a connection.
  - **modem_setup.sh**: Configures the modem and sets up the PPP connection.

- **systemd/**: Contains the systemd service file for managing the execution of the connection scripts at boot.

  - **4g-modem-setup.service**: Ensures that the modem connection scripts are executed at boot, specifying dependencies and execution order.

- **udev/**: Contains udev rules for consistent device recognition.

  - **99-4g-hat.rules**: Creates a persistent device link for the modem.

- **docs/**: Contains additional documentation.
  - **CONFIGURATION.md**: Provides detailed configuration instructions for the scripts and systemd service.

## Prerequisites

- Ensure the Raspberry Pi runs Raspberry Pi OS.
- Confirm the A7670E 4G HAT is connected and the SIM is active.
- Clone this repository onto the device.

## Setup Instructions

1. **Clone the Repository**: Clone this repository to your Raspberry Pi.

2. **Install Dependencies**: Ensure that you have the necessary packages installed:

   ```bash
   sudo apt update
   sudo apt install minicom usb-modeswitch ppp isc-dhcp-client
   ```

3. **Configure udev Rules**: Copy the udev rules to the appropriate directory:

   ```bash
   sudo cp udev/99-4g-hat.rules /etc/udev/rules.d/
   sudo udevadm control --reload-rules
   sudo udevadm trigger
   ```

4. **Enable the Systemd Service**: Copy the systemd service file and enable it:

   ```bash
   sudo cp systemd/4g-modem-setup.service /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable 4g-modem-setup.service
   ```

5. **Make the scripts executable**:

   ```bash
   chmod +x activate_4g.sh modem_setup.sh
   ```

6. **Reboot**: Restart your Raspberry Pi to apply the changes and start the connection process automatically.

## Configuration

### Modem Activation (`activate_4g.sh`)

- Set `AT_PORT` to the persistent device link (for example `/dev/modem_at`).
- Update modem-specific AT commands such as `AT+CGACT=1,1` if your carrier requires different PDP activation.
- The script now requests an IP lease via `dhclient -1`, ensures the default route is bound to `UPLINK_IFACE`, and validates connectivity (override `PING_TARGET`, `PING_TIMEOUT`, or `PING_COUNT` as needed).
- Use `scripts/activate_4g.sh --check` to probe link health without altering the connection state.

### Modem setup (`modem_setup.sh`)

- Ensure PPP peer files (for example `/etc/ppp/peers/provider`) match the APN, username, and password from your carrier.
- Confirm chat scripts or credentials referenced inside the script exist and are executable.

### Connection Health Checks

- `scripts/activate_4g.sh --check` probes link status without altering modem state.
- `scripts/activate_4g.sh --check-and-up` validates connectivity and triggers recovery when needed.
- Override `PING_TARGET`, `PING_TIMEOUT`, or `PING_COUNT` to tune the test.

### Systemd Service (`systemd/4g-modem-setup.service`)

- Validate `After`/`Requires` directives include any services that must finish before modem setup.
- Ensure `ExecStart` references the correct absolute path to `modem_setup.sh`.

### Udev Rule (`udev/99-4g-hat.rules`)

- Confirm vendor and product IDs match the modem (`lsusb` helps identify them).
- Verify the resulting symlink (e.g., `/dev/modem_at`) aligns with the paths used in the scripts.

### Final Checks

```bash
sudo systemctl restart 4g-modem-setup.service
sudo systemctl status 4g-modem-setup.service
journalctl -u 4g-modem-setup.service
```

If everything is configured correctly, reboot the Pi to ensure the connection comes up automatically.

## Usage

- The modem activation runs on boot through the systemd service.
- Use the watchdog script through cron or a systemd timer to maintain connectivity.
- Inspect logs via `journalctl -u 4g-modem-setup.service` for troubleshooting.

## Optional Cron Watchdog

Open the crontab for editing:

```bash
crontab -e
```

Add the following lines to run the activation script at reboot and the watchdog script every 5 minutes:

```bash
@reboot /bin/sleep 60 && /home/pi/raspi-4g-autoconnect/activate_4g.sh --up >> /home/pi/logs/4g-activate.log 2>&1
*/5 * * * * /home/pi/raspi-4g-autoconnect/activate_4g.sh --check-and-up >> /home/pi/logs/4g-health.log 2>&1
```

Ensure both scripts are executable and the log directory is writable:

```bash
mkdir -p /home/pi/logs
```
