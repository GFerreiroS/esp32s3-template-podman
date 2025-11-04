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
* Serial port and IDF path managed through `.vscode/env.json`.
* One-time setup script (`setup.sh` / `setup.ps1`) handles configuration.
* Project-specific VS Code setup for consistent environments.

---

> **Note**
> To create your own project from this template without pushing changes to the original repository:

**Option 1 — Use this template (recommended)**

1. On GitHub, click **“Use this template” → “Create a new repository”**.
2. Choose a name for your new project and create it under your account.
3. Clone your new repository:

   ```bash
   git clone https://github.com/<your-username>/<your-project>.git
   cd <your-project>
   ```
4. Run the setup script to initialize the environment:

   ```bash
   ./setup.sh -d /dev/ttyACM0
   ```

**Option 2 — Fork this repository manually**

1. Fork this repository on GitHub.
2. Clone your fork instead of the original:

   ```bash
   git clone https://github.com/<your-username>/<your-fork>.git
   cd <your-fork>
   ```
3. Run the setup script to configure your environment:

   ```bash
   ./setup.sh
   ```

Both methods give you a fully independent project with its own Git history and remote origin.


---

### Setup

Run the setup script once to configure the environment.

**Linux/macOS:**

```bash
./setup.sh
```

**Windows (PowerShell):**

```powershell
.\setup.ps1
```

Available flags:

| Flag                    | Description                                                                   |
| ----------------------- | ----------------------------------------------------------------------------- |
| `-d, --device <port>`   | Sets the serial port (e.g. `/dev/ttyACM0` or `COM3`).                         |
| `-m, --menu`            | Launches `menuconfig` inside the container.                                   |
| `-l, --location <path>` | Mirrors ESP-IDF headers for IntelliSense and updates `c_cpp_properties.json`. |

Example:

```bash
./setup.sh -d /dev/ttyACM0 -l ~/.idf-sysroot/idf -m
```

The script creates `.vscode/env.json` storing your configuration.

---

### Usage in Visual Studio Code

#### Build

`ESP: Build (Podman)`

Runs a full containerized build and generates `build/compile_commands.json` for IntelliSense.

#### Flash

`ESP: Flash (Podman)`

Flashes the firmware using the serial port defined in `.vscode/env.json`.

#### Monitor

`ESP: Monitor (Podman)`

Opens the serial monitor for ESP-IDF logs.
Exit with `Ctrl+]`.

#### Menuconfig

`ESP: Menuconfig (Podman)`

Opens the ESP-IDF `menuconfig` interface inside the container.

#### Build + Flash + Monitor

`ESP: Build+Flash+Monitor (Podman)`

Builds, flashes and monitors in a single task.

#### Clean

`ESP: Clean (keep sdkconfig)`

Cleans all compiled objects and artifacts. Is the same as ```idf.py clean```

#### Distclean

`ESP: Distclean (removes sdkconfig!)`

Cleans everything related to the build including sdkconfig and sdkconfig.old. Is the same as ```idf.py distclean```

---

### License

ESP-IDF and its toolchain remain licensed by Espressif.
Do whatever you want with this template.
