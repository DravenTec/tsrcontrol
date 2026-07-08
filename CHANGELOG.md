# Changelog

All notable changes to this project will be documented in this file.

## Unreleased

### Fixed
- Recorder log output no longer appears hours late (or gets lost on
  restarts): units created by old versions lacked
  `Environment=PYTHONUNBUFFERED=1`, so Python buffered the periodic check
  messages instead of writing them to the journal every 15 seconds.

### Added
- GitHub Actions workflow that automatically attaches the `tsrcontrol`
  script from the tagged commit to every published release.
- Unit repair pass on startup: existing `tsr-<streamer>` units created from
  older templates are rewritten with the current template (after
  confirmation). The quality argument is preserved and running recorders are
  restarted. Up-to-date units are never touched.
- The unit template is now a single function (`render_unit`) shared by
  create service, migration and repair.
- Installation as a system command: `tsrcontrol.sh` was renamed to
  `tsrcontrol` and the README documents installing it root-only via
  `install -m 0700 -o root -g root tsrcontrol /usr/local/sbin/tsrcontrol`
  (including update and uninstall instructions).
- Recorder units are now created as `tsr-<streamer>.service` to prevent
  collisions with existing system units (e.g. a streamer named `cron`).
- Automatic migration offer on startup for units created by older versions
  (`<streamer>.service` → `tsr-<streamer>.service`). Units are recreated
  from the current template; the quality argument and each recorder's
  enabled/running state are preserved.
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
