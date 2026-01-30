# Changelog

All notable changes to this project will be documented in this file.

## Unreleased
### Added
- Safer stream list persistence and array-based handling for recorder menus.
- Streamer input validation and duplicate detection to prevent conflicting services.
- Systemd daemon reloads after unit changes and improved active recorder listing.

### Changed
- Recorder unit files are overwritten (not appended) to avoid duplicate entries.
- Systemctl calls are quoted consistently for safer service handling.
