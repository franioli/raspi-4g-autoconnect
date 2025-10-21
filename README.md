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
  - [Usage and Cron / Scheduling](#usage-and-cron--scheduling)
  - [Configuration and tuning](#configuration-and-tuning)
  - [Troubleshooting](#troubleshooting)

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

4. **Enable the Systemd Service**: Copy the systemd service file and enable it (if using systemd for startup):

   ```bash
   sudo cp systemd/4g-modem-setup.service /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable 4g-modem-setup.service
   ```

5. **Make the scripts executable**:

   ```bash
   chmod +x ./activate_4g.sh ./modem_setup.sh
   ```

6. **Create and secure log directory** (recommended for cron logging):

   ```bash
   sudo mkdir -p /var/log/raspi-4g
   sudo chown root:root /var/log/raspi-4g
   sudo chmod 755 /var/log/raspi-4g
   ```

7. **Reboot**: Restart your Raspberry Pi to apply the changes and start the connection process automatically.

8. Install and enable the provided systemd units (recommended — prefer this to cron)

- Copy the service and timer units to systemd and enable them so activation runs reliably at boot and periodic health checks run as root:

```bash
sudo cp systemd/4g-modem-setup.service /etc/systemd/system/
sudo cp systemd/4g-modem-health.service /etc/systemd/system/
sudo cp systemd/4g-modem-health.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now 4g-modem-setup.service
sudo systemctl enable --now 4g-modem-health.timer
```

Notes:

- The activator script is expected at: /home/pi/raspi-4g-autoconnect/activate_4g.sh
- Default AT port (AT_PORT) is /dev/ttyUSB1; udev rule also creates /dev/modem_at if used.
- The boot oneshot service runs the script with --up; the timer triggers --check-and-up every 5 minutes to keep the connection persistent.

## Configuration

### Modem Activation (`activate_4g.sh`)

- Set `AT_PORT` to the persistent device link (for example `/dev/modem_at`).
- Update modem-specific AT commands such as `AT+CGACT=1,1` if your carrier requires different PDP activation.
- The script now requests an IP lease via `dhclient -1`, ensures the default route is bound to `UPLINK_IFACE`, and validates connectivity (override `PING_TARGET`, `PING_TIMEOUT`, or `PING_COUNT` as needed). Tune retry behavior with `CHECK_RETRIES` and `CHECK_DELAY`.
- Use `./activate_4g.sh --check` to probe link health without altering the connection state.

### Modem setup (`modem_setup.sh`)

- Ensure PPP peer files (for example `/etc/ppp/peers/provider`) match the APN, username, and password from your carrier.
- Confirm chat scripts or credentials referenced inside the script exist and are executable.

### Connection Health Checks

- `./activate_4g.sh --check` probes link status without altering modem state.
- `./activate_4g.sh --check-and-up` validates connectivity and triggers recovery when needed.
- Override `PING_TARGET`, `PING_TIMEOUT`, `PING_COUNT`, `CHECK_RETRIES`, or `CHECK_DELAY` to tune the test.

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

## Usage and Cron / Scheduling

- The activation script is located at the repository root: ./activate_4g.sh
- It supports:
  - --up : force activation (default)
  - --check : only probe connectivity and return success/failure
  - --check-and-up : probe and run recovery if necessary

Running manually with logs (recommended when testing):

- If you need to run the script and capture output to a root-owned logfile, redirecting with sudo requires a helper because shell redirection happens in your shell, not under sudo. Use tee:

```bash
# append output to the file as root
sudo /home/pi/raspi-4g-autoconnect/activate_4g.sh --up 2>&1 | sudo tee -a /var/log/raspi-4g/activate.log >/dev/null

# or for a quick check-only run
sudo /home/pi/raspi-4g-autoconnect/activate_4g.sh --check 2>&1 | sudo tee -a /var/log/raspi-4g/health.log >/dev/null
```

Cron scheduling (recommended to run as root so network commands and /etc/resolv.conf changes work without extra wrappers):

Option A — add to root crontab:

- Edit root crontab:

```bash
sudo crontab -e
```

- Add these lines (use absolute paths):

```
@reboot /bin/sleep 60 && /home/pi/raspi-4g-autoconnect/activate_4g.sh --up >> /var/log/raspi-4g/activate.log 2>&1
*/5 * * * * /home/pi/raspi-4g-autoconnect/activate_4g.sh --check-and-up >> /var/log/raspi-4g/health.log 2>&1
```

Option B — system cron file (/etc/cron.d) — run as root (explicit user field):

- Create /etc/cron.d/raspi-4g-autoconnect with contents (as root):

```
@reboot root /bin/sleep 60 && /home/pi/raspi-4g-autoconnect/activate_4g.sh --up >> /var/log/raspi-4g/activate.log 2>&1
*/5 * * * * root /home/pi/raspi-4g-autoconnect/activate_4g.sh --check-and-up >> /var/log/raspi-4g/health.log 2>&1
```

If you must use the pi user's crontab, wrap the command so redirection runs as root:

```
@reboot /bin/sleep 60 && sudo bash -c '/home/pi/raspi-4g-autoconnect/activate_4g.sh --up >> /var/log/raspi-4g/activate.log 2>&1'
*/5 * * * * sudo bash -c '/home/pi/raspi-4g-autoconnect/activate_4g.sh --check-and-up >> /var/log/raspi-4g/health.log 2>&1'
```

Notes and recommendation:

- Using a root systemd service + timer is preferable to a user cron entry for this use-case because:
  - systemd can order startup after the modem device and the network is online
  - the units run as root so DHCP/route/resolv.conf updates work without sudo wrappers
  - timers are easier to manage with systemd tools (systemctl status/enable/disable)

If you already have cron entries for activation/health checks, you can remove them and use the systemd timer instead:

```bash
# remove from pi crontab if present
crontab -e
# delete the @reboot and */5 entries related to activate_4g.sh
```

## Configuration and tuning

- Key environment variables you can override (export before cron or modify in script):
  - AT_PORT (default: /dev/modem_at or /dev/ttyUSB1)
  - UPLINK_IFACE (default: usb0)
  - DNS_SERVERS (default: "1.1.1.1 8.8.8.8")
  - PING_TARGET (default: www.google.com)
  - PING_COUNT, PING_TIMEOUT
  - CHECK_RETRIES (number of ping attempts after activation; tune to allow interface settle)
  - CHECK_DELAY (seconds between ping attempts)

Example to test with custom values:

```bash
sudo AT_PORT=/dev/ttyUSB1 UPLINK_IFACE=usb0 CHECK_RETRIES=5 CHECK_DELAY=4 /home/pi/raspi-4g-autoconnect/activate_4g.sh --check-and-up
```

## Troubleshooting

- "Permission denied" when redirecting to /var/log/...:
  - Use sudo tee as shown above, or run via root crontab.
- Activation failed immediately but a later check succeeds:
  - The interface may need a few seconds after DHCP/route for ARP / NAT / carrier path to settle. Increase CHECK_RETRIES and CHECK_DELAY.
- If dhclient reports a lease from a private gateway (e.g., 192.168.x.x) but ping fails:
  - Check carrier gateway reachability, APN and that the PDP context is correct for your provider.
- Logs:
  - Inspect /var/log/raspi-4g/\*.log (if using the recommended log dir)
  - Check system journal for systemd service logs: sudo journalctl -u 4g-modem-setup.service
