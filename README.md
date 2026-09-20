# ASRock 970 Pro3 R2.0 Fan Control Configuration

Custom fan speed curve configuration for Ubuntu Linux on the **ASRock 970 Pro3 R2.0** motherboard paired with the **AMD FX-8320** CPU.

---

## Hardware Context

- **Motherboard:** ASRock 970 Pro3 R2.0
- **Super I/O Sensor Chip:** Nuvoton NCT6776 (`nct6775` kernel module)
- **CPU:** AMD FX-8320 Eight-Core Processor (125W TDP)
- **Controlled Header:** CPU Fan 2 / PWM2 (`fan2_input` / `pwm2`) & PWM1/PWM3

---

## Thermal Curve Settings

| Parameter | Value | Description |
| :--- | :--- | :--- |
| **`MINPWM`** | `26` | Minimum duty cycle (~10% of 255) for quiet operation |
| **`MINSTOP`** | `26` | Prevents fancontrol from stopping the fan completely |
| **`MINSTART`** | `100` | Spin-up PWM setting (~39% of 255) |
| **`MINTEMP`** | `45°C` | Below this socket temperature, requests ~10% PWM |
| **`MAXTEMP`** | `62°C` | Reaches 100% PWM at a CPU socket reading of 62°C |
| **`INTERVAL`**| `10s` | Sensor polling frequency |

> [!IMPORTANT]
> This configuration uses `temp2_input` (CPUTIN / CPU socket), not the CPU core sensor. The 62°C setting is a configured full-speed threshold, not a statement of the processor’s rated temperature limit. Verify sensor and fan mappings before using this configuration on another machine.

---

## Files

- [`fancontrol.conf`](./fancontrol.conf) — The configuration file used by `/etc/fancontrol`.
- [`install.sh`](./install.sh) — Quick-setup script to reinstall packages, configure modules, and apply settings.

---

## Quick Commands

### Check Current Fan Speed and Temperatures
```bash
sensors
```

### Check Service Status
```bash
systemctl status fancontrol
```

### Reapply / Install
```bash
sudo ./install.sh
```

## Observed Fan Speeds

On this machine, fan2 reported approximately 1,120 RPM at PWM 26. A brief test at PWM 20 produced approximately 1,110–1,130 RPM with no noticeable noise reduction. At full PWM (255), initial readings reached approximately 1,850 RPM. These are observations, not guaranteed minimum or maximum speeds.
