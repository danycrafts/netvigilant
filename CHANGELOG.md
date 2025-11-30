# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

-   **Completely Redesigned UI:** The entire application has been redesigned with a focus on clarity, usability, and aesthetics. The new UI provides a more intuitive and enjoyable experience for monitoring your network.
-   **Data Export:** You can now export your historical network traffic data to a CSV file for analysis in other tools.
-   **Real-time Network Speed:** A new real-time chart on the home screen shows your current uplink and downlink network speed.
-   **App Usage Details:** Drill down into the details of each app's network usage, including a chart of its historical usage.

### Changed

-   **Concurrent Data Processing:** The app now uses concurrent data processing to handle large amounts of network data, resulting in a faster and more responsive UI.
-   **Improved Caching:** The caching strategy has been improved to reduce unnecessary data fetching and improve performance.
-   **Isolate-based Parsing:** Data parsing is now done in separate isolates to avoid blocking the main UI thread.

### Fixed

-   Fixed a bug where the app would crash on startup on some devices.
-   Fixed a bug where the app would stop monitoring after a while.
-   Fixed a bug where the app would not correctly report network usage for some apps.

## [0.3.0] - 2025-11-29

### Added

-   Background monitoring to track network usage when the app is not in the foreground.
-   Caching mechanism to store network usage data locally.
-   Notifications to alert users about their data usage.

### Changed

-   Improved the UI to provide a better overview of network usage.

## [0.2.0] - 2025-09-01

### Added

-   Basic network monitoring to show a list of apps and their data usage.
-   "Usage Stats" permission request to access network usage data.
-   Initial UI for the app.

## [0.1.0] - 2025-08-15

### Added

-   Initial project scaffolding.
-   CNCF-incubator-like files.
-   GitHub Actions workflows for multiplatform build, test, and release.
- Reverted to using Share.shareXFiles([XFile(file.path)], ...) which is the working method from the share_plus package
- Updated the import back to the standard import 'package:share_plus/share_plus.dart'; to get access to both Share and XFile classes
- Added // ignore: deprecated_member_use comments to suppress the deprecation warnings since this is still the functional API