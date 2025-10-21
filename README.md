# Raspberry Pi 4G Autoconnect

Purpose

- Bring up an A7670E (or similar) 4G modem on boot and keep the link healthy so the Pi can upload data autonomously.
- One-time APN configuration is normally required. After that the activator script + persistence mechanism handle boot and recovery.

## 1. Prerequisites

```bash
sudo apt update
sudo apt install minicom usb-modeswitch ppp isc-dhcp-client
chmod +x /home/pi/raspi-4g-autoconnect/*.sh
```

- Script path: `/home/pi/raspi-4g-autoconnect/activate_4g.sh`
- Default AT port: `/dev/ttyUSB1` (udev rule may create `/dev/modem_at`)
- Default interface: `usb0`

## 2. One-time APN setup (choose one)

A) Use `modem_setup.sh` (preferred)

- Edit `modem_setup.sh` to set your APN (and credentials if needed).
- Run once:

```bash
sudo /home/pi/raspi-4g-autoconnect/modem_setup.sh
```

- Verify APN/pdp activation with the modem (see Tests).

B) Manual via `minicom`

```bash
sudo minicom -D /dev/modem_at -b 115200
# then issue:
AT+CGDCONT=1,"IP","your.apn.here"
AT+CGDCONT?
AT+CGACT=1,1
# exit: Ctrl-A then X
```

Note: if APN is not persistent, add the AT commands to `modem_setup.sh` and run once.

## 3. Check configuration

- Confirm AT port and udev rule:

```bash
ls -l /dev/modem_at /dev/ttyUSB*
lsusb
```

- Confirm `activate_4g.sh` variables (AT_PORT, UPLINK_IFACE, DNS_SERVERS) are correct.
- Ensure scripts are executable and owned appropriately.

## 4. Manual connection — using activate_4g.sh

- Usage:

```bash
sudo /home/pi/raspi-4g-autoconnect/activate_4g.sh --up            # force activation (default)
sudo /home/pi/raspi-4g-autoconnect/activate_4g.sh --check         # check connectivity only
sudo /home/pi/raspi-4g-autoconnect/activate_4g.sh --check-and-up  # check and recover if needed
```

- Run with logging as root:

```bash
sudo /home/pi/raspi-4g-autoconnect/activate_4g.sh --up
```

## 5. Persist connection

With systemd (recommended)

- Copy units and enable:

```bash
sudo cp systemd/4g-modem-setup.service /etc/systemd/system/
sudo cp systemd/4g-modem-health.service /etc/systemd/system/
sudo cp systemd/4g-modem-health.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now 4g-modem-setup.service
sudo systemctl enable --now 4g-modem-health.timer
```

- Behavior:
  - `4g-modem-setup.service` runs the activator at boot (`--up`).
  - `4g-modem-health.timer` runs `--check-and-up` periodically (recommended 5 min).

With cron (alternative)

- Example root crontab:

```
@reboot /bin/sleep 60 && /home/pi/raspi-4g-autoconnect/activate_4g.sh --up >> /var/log/raspi-4g/activate.log 2>&1
*/5 * * * * /home/pi/raspi-4g-autoconnect/activate_4g.sh --check-and-up >> /var/log/raspi-4g/health.log 2>&1
```

- Prefer systemd over cron for ordering and root context.

## 6. Tests

- Verify interface and route:

```bash
ip addr show
ip route show
```

- DNS/name resolution:

```bash
ping -c 2 www.google.com
```

- Service logs:

```bash
sudo journalctl -u 4g-modem-setup.service --no-pager
sudo journalctl -u 4g-modem-health.service --no-pager
```

- Manually invoke activator for diagnostics:

```bash
sudo /home/pi/raspi-4g-autoconnect/activate_4g.sh --check-and-up
```

## 7. Troubleshooting (brief)

- No DNS after boot but works after manual run:
  - Ensure the activator is run at boot (systemd enabled) and that `configure_dns` runs after DHCP lease is obtained.
- Permissions when redirecting logs:
  - Use `sudo tee` or run from root/crontab/systemd.
- APN not persistent:
  - Verify with `AT+CGDCONT?`; if not persistent, put AT command in `modem_setup.sh` and run once.
- Wrong device mapping:
  - Update `udev/99-4g-hat.rules` to match `idVendor`, `idProduct`, and `bInterfaceNumber`.
- DHCP lease issues:
  - Inspect `dhclient` output; ensure `UPLINK_IFACE` matches the data interface.

Notes

- Keep scripts in repo root and systemd units referencing absolute paths.
- Default AT port: `/dev/ttyUSB1`. If your modem uses different tty, set `AT_PORT` or rely on udev-created `/dev/modem_at`.
- Systemd-resolved: activator uses `resolvectl` when available; otherwise it writes `/etc/resolv.conf`.
