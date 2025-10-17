# Raspberry Pi 4G Autoconnect

This project provides a set of scripts and configurations to enable automatic connection to a 4G modem (A7670E) on a Raspberry Pi. The scripts ensure that the modem is activated, the connection is established, and that the connection is monitored for reliability.

## Project Structure

The project consists of the following components:

- **scripts/**: Contains the main scripts for modem activation and connection management.

  - **activate_4g.sh**: Activates the 4G modem by sending AT commands to establish a connection.
  - **modem_bootstrap.sh**: Initializes the modem and sets up the PPP connection, checking if the modem is connected.
  - **watchdog.sh**: Monitors the connection status and attempts to reconnect if the connection is lost.

- **systemd/**: Contains the systemd service file for managing the execution of the connection scripts at boot.

  - **4g-modem-setup.service**: Ensures that the modem connection scripts are executed at boot, specifying dependencies and execution order.

- **udev/**: Contains udev rules for consistent device recognition.

  - **99-4g-hat.rules**: Creates a persistent device link for the modem.

- **docs/**: Contains additional documentation.
  - **CONFIGURATION.md**: Provides detailed configuration instructions for the scripts and systemd service.

## Setup Instructions

1. **Clone the Repository**: Clone this repository to your Raspberry Pi.

2. **Install Dependencies**: Ensure that you have the necessary packages installed:

```bash
sudo apt update
sudo apt install minicom usb-modeswitch ppp
```

3. **Configure udev Rules**: Copy the udev rules to the appropriate directory:

```bash
sudo cp udev/99-4g-hat.rules /etc/udev/rules.d/
```

4. **Enable the Systemd Service**: Copy the systemd service file and enable it:

```bash
sudo cp systemd/4g-modem-setup.service /etc/systemd/system/
sudo systemctl enable 4g-modem-setup.service
```

5. **Edit Configuration**: Modify the scripts as necessary to match your modem's settings and APN.

6. Make the scripts executable:

   ```bash
   chmod +x scripts/activate_4g.sh
   chmod +x scripts/modem_bootstrap.sh
   chmod +x scripts/watchdog.sh
   ```

7. **Reboot**: Restart your Raspberry Pi to apply the changes and start the connection process automatically.

## Usage

- The scripts will automatically attempt to connect to the 4G modem on boot.
- The watchdog script can be set up as a cron job or systemd timer to run periodically and ensure persistent connectivity.

- Check the status of the systemd service:

```bash
sudo systemctl status 4g-modem-setup.service
```

- Review logs for any errors:

```bash
journalctl -u 4g-modem-setup.service
```

For detailed configuration options, refer to the [CONFIGURATION.md](docs/CONFIGURATION.md) file.

## Configure Cron Watchdog

Open the crontab for editing:

```bash
crontab -e
```

Add the following lines to run the activation script at reboot and the watchdog script every 5 minutes:

```bash
@reboot /bin/sleep 60 && /home/pi/raspi-4g-autoconnect/scripts/activate_4g.sh >> /home/pi/logs/4g-activate.log 2>&1
*/5 * * * * /home/pi/raspi-4g-autoconnect/scripts/watchdog.sh >> /home/pi/logs/4g-watchdog.log 2>&1
```

Ensure both scripts are executable and the log directory is writable:

```bash
mkdir -p /home/pi/logs
```
