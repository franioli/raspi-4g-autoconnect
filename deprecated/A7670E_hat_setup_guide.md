📝 4G HAT (A7670E) Setup

This guide provides the complete, robust, step-by-step procedure to configure your 4G HAT (A7670E/SIM7600) for persistent, priority internet connectivity on a Raspberry Pi Zero, ensuring the USB device is reliably recognized after reboot.

# Prerequisites

- Raspberry Pi Zero W/2W/3A+ (or similar) with Raspberry Pi OS.
- 4G HAT (A7670E/SIM7600) with activated SIM card.
- Crucial: A stable, high-quality, powered USB hub to connect the HAT.
- The user pi has sudo privileges.

# Step 1: Configure Raspberry Pi Serial Port ⚙️

The 4G HAT uses a hardware UART (serial port) for certain communications (though data is over USB). We must enable the serial hardware interface and ensure the operating system doesn't use it for a login shell.

1. Open the Raspberry Pi Configuration tool:

```bash
sudo raspi-config
```

2. Navigate to 3 Interface Options (or 5 Interfacing Options).
3. Select P6 Serial Port.
4. When prompted:

   - Would you like a login shell to be accessible over serial? Select No.
   - Would you like the serial port hardware to be enabled? Select Yes.

5. Select Finish and choose Yes to reboot the system.

# Step 2: Hardware Setup, Tool Installation, and USB ID Identification 🔍

2.1 Hardware Setup

    - Mount the HAT: Connect the 4G HAT to the Raspberry Pi GPIO pins and attach the 4G antenna.
    - Insert SIM Card: Ensure the activated SIM card is correctly inserted.
    - Connect USB: Connect the HAT's USB data port to the powered USB hub, and then connect the hub to the Raspberry Pi Zero's USB port.

2.2 Install Tools

```bash

sudo apt update
sudo apt install minicom usb-modeswitch
```

### Step 3: Configure Modem (APN & Activation)

**AT command quick reference**

- `AT` — Check modem response
- `AT+CPIN?` — Check SIM status (`READY` is good)
- `AT+CGDCONT=1,"IP","mobile.vodafone.it"` — Set APN (replace `mobile.vodafone.it` with your provider’s APN)
- `AT+CGACT=1,1` — Activate PDP context (connect)
- `AT+CREG?` — Check registration status (`0,1` or `0,5` is good)
- `AT+DIALMODE=0` — Set dial mode before reboot
- `AT$MYCONFIG="usbnetmode",0` — Configure USB networking mode before reboot

**Procedure**

1.  Connect the HAT via micro-USB and confirm the modem port appears:
    ```bash
    sudo ls /dev/ttyUSB*
    ```
2.  Start Minicom on the AT command port:
    ```bash
    sudo minicom -D /dev/ttyUSB1
    ```
3.  In Minicom, enter each command from the quick reference in CAPS and press Enter, verifying an `OK` response after each.
4.  Apply the mode change and reboot the module:

```bash
AT+DIALMODE=0
```

This takes a while; wait for the module to restart (wait for +CPIN: READY). Check the response with: `AT+CPIN?`

Then set the USB network mode:

```bash
    AT$MYCONFIG="usbnetmode",0
```

5.  After the module restarts, reissue:

```
 AT+CPIN?
 AT+CGDCONT=1,"IP","mobile.vodafone.it"
 AT+CGACT=1,1
 AT+CREG?
```

6. Exit Minicom with `Ctrl-A`, then `X`, and confirm.
7. Verify the new USB interface:

```bash
ifconfig
```

You should see a new interface (usually `usb0`) with an IP address.

1. Apply the IP address of the USBx port.

```bash
sudo dhclient -v usb0
```

2. Test the USBx port and try to ping a website, for example, google.com

```bash
  sudo ping -I usb0 www.google.com
```

These instructions are taken from the [documentation](https://www.waveshare.com/wiki/A7670E_Cat-1_HAT#Hardware)

# Step 4: Implement Robust USB Mode Switching Fix (Persistence) 🔒

This uses the IDs from Step 2.3 to reliably force the modem into the working state on every boot.

4.1 Identify USB Vendor and Product IDs

    You need two sets of IDs for the mode-switching fix: the Working Modem Mode ID and the Initial/Failed Mode ID.

    Find the Working Modem Mode ID (when /dev/ttyUSB\* is present): If the modem is currently working, run:

    ```bash
    lsusb
    # Look for a device name like 'SIM Tech' or 'Quectel Wireless'.
    ```

    Example Working Modem Mode ID: 1e0e:9001

4.2: Create a Custom udev Rule (Automatic Naming)

A udev rule ensures the modem receives a predictable name and permissions whenever it appears.

```bash
sudo nano /etc/udev/rules.d/99-4g-hat.rules
```

Paste the following (replace `1e0e` and `9001` with your modem’s IDs):

```udev
# Rule for 4G HAT (Change IDs to match your device)
SUBSYSTEM=="tty", ATTRS{idVendor}=="1e0e", ATTRS{idProduct}=="9011", SYMLINK+="modem_at"
# This creates a persistent link named /dev/modem_at for the AT command port
```

Reload and trigger the rule:

```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```

## Step 2.5: Modify the Activation Service to Be Robust

Update the systemd service to wait for `/dev/modem_at` before running.

```bash
sudo nano /etc/systemd/system/4g-modem-setup.service
```

Update the content to use Wants for the /dev/modem_at device:

```ini
[Unit]
Description=Activate 4G Modem PDP Context
# Wait for the USB device /dev/modem_at to exist
Requires=dev-modem_at.device
After=network-online.target dev-modem_at.device

[Service]
Type=oneshot
# Use the robust device link
ExecStart=/usr/local/bin/activate_4g.sh

[Install]
WantedBy=multi-user.target
```

Modify the activation script to use the new link and reduce the initial sleep:

```bash
sudo nano /usr/local/bin/activate_4g.sh
```

```bash
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
```

Note: If your AT port was not the one that corresponds to ttyUSB0, you'll need to create similar udev rules for all four ports and ensure you link the correct one to modem_at.

Reload the systemd configuration:

```bash
sudo systemctl daemon-reload
sudo systemctl enable 4g-modem-setup.service
```

Check the service status:

```bash
sudo systemctl status 4g-modem-setup.service
```

# 3. Final Reboot and Test 🔄

With the udev rule providing a stable device name and the systemd service waiting for that name to appear, the connection process should be much more resilient to boot timing issues.

Reboot the Raspberry Pi:

```bash
sudo reboot
```

After rebooting, verify:
Robust Device Link:

```bash
ls -l /dev/modem_at
# This should show a link to one of the /dev/ttyUSBx devices
```

Connection Status:

```bash
ip a
# Check for the 192.168.0.x IP on the usb0 interface.
```

Internet Connectivity:

```bash
ping -I usb0 www.google.com
# Confirm you have internet access.
```
