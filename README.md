## ESP32-S3 Podman + VS Code Template

### Overview

This repository provides a complete C++ environment for the ESP32-S3 using Podman.
All build, flash, and monitor operations run inside the container through predefined VS Code tasks, so no ESP-IDF installation is needed on the host.

The setup is self-contained and reproducible. Once cloned, the project is ready to build in VS Code, with full IntelliSense support through `compile_commands.json`.

---

### Features

* No ESP-IDF installation required on the host.
* All build and flash tasks execute in a Podman container.
* IntelliSense configuration automatically generated.
* Serial port detection on flash and monitor.
* Project-specific VS Code setup for consistent environments.

---

### Usage in Visual Studio Code

#### Build

Runs a full containerized build and generates `build/compile_commands.json` for IntelliSense.

**Task:**
`ESP: Build (Podman)`

#### Flash

Flashes the firmware to the connected ESP32-S3 board.
If no port is entered, the task automatically detects `/dev/serial/by-id/*` or the first `/dev/ttyACM*`/`/dev/ttyUSB*`.

**Task:**
`ESP: Flash (Podman, choose port)`

#### Monitor

Opens the serial monitor to view ESP-IDF log output.

**Task:**
`ESP: Monitor (Podman, choose port)`

Exit the monitor with `Ctrl+]`.

#### Menuconfig

Opens the ESP-IDF `menuconfig` interface inside the container.

**Task:**
`ESP: Menuconfig (Podman)`

---

### License

ESP-IDF and its toolchain remain licensed by Espressif.
Do whatever you want with this template