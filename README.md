# NetVigilant

NetVigilant is a Flutter application designed to help users monitor their network usage and manage their digital habits. It provides detailed information about network connectivity, data usage, and more.

## Key Features

* **Network Monitoring:** Get real-time information about your WiFi and mobile network connections.
* **Authentication:** Securely log in, register, or use the app in guest mode.
* **User Profiles:** Manage your user profile and notification settings.
* **Permissions:** The app requests the necessary permissions to provide accurate network and app usage statistics.

## Prerequisites

* Flutter SDK
* Dart SDK

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/netvigilant.git
   ```
2. Install the dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```

## Architecture

This project follows the Clean Architecture principles, with a clear separation of concerns between the data, domain, and presentation layers. It uses the `provider` package for state management.
