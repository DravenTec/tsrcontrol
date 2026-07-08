# Changelog

All notable changes to this project will be documented in this file.

## Unreleased

### Added
- Recorder units are now created as `tsr-<streamer>.service` to prevent
  collisions with existing system units (e.g. a streamer named `cron`).
- Automatic migration offer on startup for units created by older versions
  (`<streamer>.service` → `tsr-<streamer>.service`), preserving each
  recorder's enabled/running state.
- Root privilege check on startup with a clear error message.
- Failed `systemctl` calls now show the actual error message in the result
  dialogs instead of a bare "failed".

### Changed
- `ExecStart` now uses the absolute path to `tsr.py`
  (`/home/<user>/tsr.py`) instead of relying on the working directory.
- `SyslogIdentifier` follows the new unit name (`tsr-<streamer>`).
- README rewritten to describe the whiptail TUI, its menu options, the new
  service naming scheme and the classic script variant.

## 04.03.2026

### Added
- Whiptail-based TUI replacing the plain text menu; the previous script is
  kept as `tsrcontrol_classic.sh`.
- Restart action, journal log viewer with configurable line count, and a
  recorder status overview in the main menu.
- Dependency check on startup and dialogs that adapt to the terminal size.
- Atomic config writes (temp file + rename) to avoid a corrupt `~/.tsrconf`.

## Older releases

### Added
- Safer stream list persistence and array-based handling for recorder menus.
- Streamer input validation and duplicate detection to prevent conflicting services.
- Systemd daemon reloads after unit changes and improved active recorder listing.

### Changed
- Recorder unit files are overwritten (not appended) to avoid duplicate entries.
- Systemctl calls are quoted consistently for safer service handling.
