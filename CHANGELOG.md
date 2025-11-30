# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Initial setup of CNCF-incubator-like files.
- GitHub Actions workflows for multiplatform build, test, and release.

### Changed

- Refactored GitHub Actions workflows to use matrix jobs and environment variables.

### Removed

### Fixed

### Security

## [0.1.0] - 2025-11-29

### Added

- Initial project scaffolding.

✅ Fixed SharePlus API to use correct method names -
- Reverted to using Share.shareXFiles([XFile(file.path)], ...) which is the working method from the share_plus package
- Updated the import back to the standard import 'package:share_plus/share_plus.dart'; to get access to both Share and XFile classes
- Added // ignore: deprecated_member_use comments to suppress the deprecation warnings since this is still the functional API