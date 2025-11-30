# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-11-30

### Added

- Completely redesigned UI for a more intuitive and enjoyable experience.
- Data export feature to export historical network traffic data to a CSV file.
- Real-time network speed chart on the home screen.
- App usage details screen with a chart of historical usage.
- Implemented concurrent data processing for faster performance.
- Isolate-based parsing to avoid blocking the main UI thread.

### Changed

- Improved caching strategy to reduce unnecessary data fetching.
- Refactored the data layer to be more robust and maintainable.

### Fixed

- Fixed a bug where the app would crash on startup on some devices.
- Fixed a bug where the app would stop monitoring after a while.
- Fixed a bug where the app would not correctly report network usage for some apps.

## [0.3.0] - 2025-10-15

### Added

- Background monitoring to track network usage when the app is not in the foreground.
- Caching mechanism to store network usage data locally.
- Notifications to alert users about their data usage.

### Changed

- Improved the UI to provide a better overview of network usage.

## [0.2.0] - 2025-09-01

### Added

- Basic network monitoring to show a list of apps and their data usage.
- "Usage Stats" permission request to access network usage data.
- Initial UI for the app.

## [0.1.0] - 2025-08-15

### Added

- Initial project scaffolding.
- CNCF-incubator-like files.
- GitHub Actions workflows for multiplatform build, test, and release.
