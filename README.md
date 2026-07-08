![GitHub](https://img.shields.io/github/license/DravenTec/tsrcontrol)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/DravenTec/tsrcontrol)
![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/DravenTec/tsrcontrol)

# Twitch Stream Recorder - Control Script

This script manages Twitch stream recorders (`tsr.py`) as systemd services through
an interactive whiptail dialog interface. It allows you to create, delete, start,
stop, restart, enable and disable recorders, and to inspect their status and logs.

Two variants are included:

- **`tsrcontrol.sh`** – the current version with a whiptail-based TUI (recommended)
- **`tsrcontrol_classic.sh`** – the older, plain text-based menu version

## Prerequisites

- Bash (Bourne Again SHell)
- `whiptail` (pre-installed on Debian/Ubuntu; part of the `newt` package elsewhere)
- `systemctl` and `journalctl` (systemd)
- `less` and `pgrep` (usually pre-installed)
- Python 3 with the `tsr.py` script located in the home directory of the
  non-root user specified during setup
- Root privileges (the script writes systemd unit files and is checked on startup)

The classic variant only requires Bash and `systemctl`.

## Getting Started

1. Clone the repository: `git clone https://github.com/DravenTec/tsrcontrol`
2. Navigate to the script directory: `cd tsrcontrol`
3. Make the script executable: `chmod +x tsrcontrol.sh`
4. Run the script as root: `sudo ./tsrcontrol.sh`

On the first run you will be asked for the non-root user that runs `tsr.py`.

## Usage

The main menu offers the following options:

1. **Start recorder** – Start a specific recorder or all known recorders.
2. **Stop recorder** – Stop a specific recorder or all known recorders.
3. **Restart recorder** – Restart a specific recorder or all known recorders.
4. **Enable recorder (autostart)** – Enable autostart for one or all recorders.
5. **Disable recorder (autostart)** – Disable autostart for one or all recorders.
6. **Status** – View the full systemd status of a recorder.
7. **Logs** – View a recorder's journal logs (with a configurable line count).
8. **Active recorders overview** – Show the state of all configured recorders
   and the currently running `tsr.py` processes.
9. **Create service** – Create, enable and start a new recorder service.
10. **Delete service** – Stop, disable and remove a recorder and its service file.
11. **Quit** – Exit the script.

The status of each recorder (`RUNNING`, `STOPPED`, `NO UNIT`) is shown directly
in the selection menus.

## Service naming

Recorder units are created as `tsr-<streamer>.service` in `/etc/systemd/system/`.
The `tsr-` prefix prevents collisions with existing system units (e.g. a streamer
named `cron` will never touch `cron.service`).

If units from an older version of this script (named `<streamer>.service`) are
found on startup, the script offers to migrate them to the new naming scheme
automatically. The enabled/running state of each recorder is preserved during
migration.

## Configuration

The script uses a configuration file located at `~/.tsrconf` to store the
non-root user and the list of known stream recorders. If the configuration
file doesn't exist, it will be created on the first run.

## License

This script is licensed under the [MIT License](LICENSE).


WARNING: This script is still under development and may contain errors and incompleteness. 
Use it at your own risk and we assume no liability for any damage or loss of data that may 
result from the use of the script. Please use the script only if you agree with the risks and 
limitations. We welcome feedback and bug reports to further improve the script.
