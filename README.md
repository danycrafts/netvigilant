# NetVigilant

NetVigilant is a powerful and performant Flutter application designed for secure, persistent acquisition and visualization of real-time and historical per-application network usage, CPU, memory, and battery statistics on Android devices. It adheres strictly to Clean Architecture principles and incorporates modern Android background execution constraints to provide users with a comprehensive overview of their device's resource consumption and network activity.

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Technical Deep Dive](#technical-deep-dive)
  - [I. Architectural Foundation and Clean Layer Definition](#i-architectural-foundation-and-clean-layer-definition)
    - [A. Layered Architecture Adherence and Native Abstraction](#a-layered-architecture-adherence-and-native-abstraction)
    - [B. Reactive Data Flow Modeling: Event Channels for Real-Time Metrics](#b-reactive-data-flow-modeling-event-channels-for-real-time-metrics)
  - [II. Deep Dive: Mandated Native API Integration and Android Constraints](#ii-deep-dive-mandated-native-api-integration-and-android-constraints)
    - [A. Critical Permission Handling and User Onboarding Flow](#a-critical-permission-handling-and-user-onboarding-flow)
    - [B. Implementation Specifics for Usage and Network Stats](#b-implementation-specifics-for-usage-and-network-stats)
    - [C. The Illusion of Per-App CPU/Memory Monitoring](#c-the-illusion-of-per-app-cpumemory-monitoring)
  - [III. Persistent Monitoring and Background Service Engineering](#iii-persistent-monitoring-and-background-service-engineering)
    - [A. WorkManager for Deferred Data Archival](#a-workmanager-for-deferred-data-archival)
    - [B. Foreground Service for Real-Time Alerts and Actions](#b-foreground-service-for-real-time-alerts-and-actions)
    - [C. Battery Optimization Mitigation Strategy](#c-battery-optimization-mitigation-strategy)
    - [D. Data Caching and Repository Synchronization](#d-data-caching-and-repository-synchronization)
  - [IV. Data Visualization, Performance, and UX Optimization](#iv-data-visualization-performance-and-ux-optimization)
    - [A. Performance Budgeting and Optimization](#a-performance-budgeting-and-optimization)
    - [B. Efficient High-Volume Data Rendering](#b-efficient-high-volume-data-rendering)
    - [C. Data Visualization and UX Principles](#c-data-visualization-and-ux-principles)
- [Getting Started](#getting-started)
- [Roadmap / Future Development](#roadmap--future-development)
- [Contributing](#contributing)
- [License](#license)

--- 

## Features

NetVigilant offers a robust set of features to help users monitor and manage their device's resource usage:

*   **Real-time Network Monitoring:** Track uplink and downlink speed continuously.
*   **Per-Application Data Usage:** View historical and current data consumption broken down by individual applications.
*   **Background Data Archival:** Automatically aggregate and store usage data in the background using `WorkManager`.
*   **Persistent Monitoring with Foreground Service:** Ensure continuous data collection and enable real-time alerts even when the app is not actively in use.
*   **Comprehensive Data Visualization:** Utilize interactive charts (e.g., bar, line charts) for clear and immediate understanding of usage patterns.
*   **Local Data Persistence:** Store historical data efficiently using `Hive` and `SQFlite` for offline access.
*   **User-friendly Interface:** Modern UI with adaptive light and dark themes, designed for smooth performance.
*   **Permission Guidance:** Guided user onboarding for critical Android permissions like `PACKAGE_USAGE_STATS`.
*   **Battery Drain Monitoring:** Provides insights into application resource intensity through battery usage as a reliable proxy.

## Architecture

NetVigilant follows a rigorous **Clean Architecture** approach, separating concerns into distinct layers:

*   **Domain Layer:** Contains the core business logic, entities (e.g., `AppUsageEntity`, `NetworkTrafficEntity`), and abstract repository interfaces (`AbstractNetworkRepository`). It is entirely platform-agnostic.
*   **Data Layer:** Implements the concrete repository logic, abstracting platform-specific details. This layer handles communication with native Android APIs via **Platform Channels** (MethodChannel for one-time requests, EventChannel for real-time streams) and manages local data persistence.
*   **Presentation Layer:** Responsible for the User Interface (UI), utilizing `flutter_riverpod` for state management. It efficiently renders data, handles user interactions, and ensures optimal performance.

Dependency injection (`get_it`, `injectable`) is used to manage service dependencies, and code generation (`json_serializable`, `freezed`, `hive_generator`) enhances efficiency for data models.

## Technical Deep Dive

### I. Architectural Foundation and Clean Layer Definition

The success of NetVigilant relies on a rigorously defined, layered architecture that isolates the business logic from platform-specific implementation details. The chosen structure—Data, Domain, and Presentation layers—ensures scalability and maintainability, particularly given the complexity introduced by native platform integration.

#### A. Layered Architecture Adherence and Native Abstraction

The core tenet of this architecture is the principle of native isolation. The Domain Layer, which defines the application's core logic, data entities, and use cases, must remain entirely agnostic to whether data originates from an external API, a local database, or, in this case, the native Android system. This decoupling is achieved by defining abstract Repository interfaces within the Domain Layer.

The concrete implementations, such as the `NetworkStatsRepositoryImpl`, reside in the Data Layer. This implementation is tasked with abstracting the complexities of Platform Channels and communicating with a specialized component, the PlatformDataSource (e.g., `AndroidNetworkDataSource`). This design ensures that the platform channel boilerplate, including method calling and data type conversion, is contained solely within the Data Layer. The data retrieved from the native host—which might be in the form of platform-specific objects like `NetworkStats.Bucket` or complex native data structures—is immediately mapped into Flutter-agnostic Dart entities and models before being passed up to the Domain Layer. This guarantees data consistency and prevents proprietary native implementation details from infiltrating higher architectural layers.

A significant architectural consideration, often overlooked in initial planning, is the requirement for explicit, type-safe channel contracts. Reliance on manually managed serialization using basic `MethodChannel` calls and untyped data structures (like string-based method names and generic `Map<String, dynamic>` payloads) introduces fragility and risks runtime errors. For an application managing complex, structured network data, it is imperative to define explicit, identical data classes in both the Dart and Kotlin/Java environments. This practice minimizes manual serialization errors and enhances the maintainability of the cross-platform communication bridge.

#### B. Reactive Data Flow Modeling: Event Channels for Real-Time Metrics

NetVigilant requires both static data retrieval and continuous, high-frequency data streaming. This necessitates a dual communication strategy leveraging two primary types of Platform Channels.

1.  **MethodChannel Usage:** This channel is employed for request-response operations, where the Dart side initiates a call and awaits a single result. Examples include fetching large blocks of historical daily aggregated statistics, executing user actions (like triggering a data-saving mode), or querying static connectivity details such as the current Wi-Fi SSID.
2.  **EventChannel Usage:** This channel is mandatory for all high-frequency, continuous data streams, such as real-time uplink and downlink speed monitoring (which requires continuous polling of TrafficStats) and immediate connectivity status changes.

The **EventChannel Stream Design** is critical for performance. The native side must utilize appropriate Android asynchronous tools, such as Kotlin Flows or RxJava, to handle the polling of TrafficStats or other real-time metrics in a dedicated background thread. Once the data is acquired and processed (e.g., speed calculated), it is pushed asynchronously to the Dart StreamController established by the EventChannel.

Managing the data flow from this high-frequency stream requires careful attention in the Presentation Layer. A continuous stream (e.g., updating five times per second) can easily force excessive, unnecessary full-screen UI rebuilds if the central state provider updates on every single event, leading to "jank" and dropped frames. Therefore, the Presentation Layer must employ granular state management techniques (such as specific Riverpod or Provider configurations). A high-frequency `StreamProvider` should feed only the small, isolated widgets that display the instantaneous speed metrics. Conversely, the main Dashboard view, which may only require aggregated or sampled data, should listen to a secondary, debounced stream derived from the original EventChannel stream, perhaps updating only every 1 to 2 seconds. This optimization is crucial for maintaining the required 60 frames per second (fps) performance target.

| Integration Layer | Component/Task | Channel Type | Data Flow Mechanism | Performance Consideration |
| :---------------- | :------------- | :----------- | :------------------ | :---------------------------------- |
| Data Layer (Dart) | Historical Query (Day/Month usage) | MethodChannel | One-time synchronous call | High data volume, low frequency |
| Data Layer (Dart) | Real-Time Speed Stream | EventChannel | Asynchronous, continuous stream | Must be rate-limited/throttled on native side |
| Domain Layer (Dart) | Connectivity Status Change | EventChannel (via connectivity_plus) | Asynchronous, event-driven | Low frequency, instant notification |

### II. Deep Dive: Mandated Native API Integration and Android Constraints

Acquiring detailed per-application network and resource usage metrics demands privileged access to core Android system services. This integration is complex, requiring specific permissions, a precise user onboarding sequence, and acknowledgment of inherent API limitations.

#### A. Critical Permission Handling and User Onboarding Flow

NetVigilant’s core functionality—tracking data usage per app—is entirely dependent on accessing the Android `NetworkStatsManager` and `UsageStatsManager`. These services are protected by the highly restricted `android.permission.PACKAGE_USAGE_STATS` permission. Unlike standard runtime permissions (like camera or location), this permission requires manual user approval through a specialized system settings screen.

The implementation must therefore include a mandatory, guided permission flow:

1.  The app checks the current permission status using a utility such as `UsageStats.checkUsagePermission()`.
2.  If access is denied, the application must present a custom informational screen to the user, clearly explaining that the permission is foundational to the app’s purpose.
3.  The app then triggers a system setting redirection, often via `UsageStats.grantUsagePermission()`, which launches the `ACTION_USAGE_ACCESS_SETTINGS` activity, directing the user to manually enable NetVigilant within the system settings list.

If the user denies the permission after being redirected, the Data Layer must be robust enough to return an `AccessDenied` state to the application. The Presentation Layer should then display a persistent prompt, as the majority of the app's core data-tracking features will be non-functional without this access.

#### B. Implementation Specifics for Usage and Network Stats

##### 1. Network Usage Measurement and Attribution

The native implementation must leverage `NetworkStatsManager` to track data usage. This manager allows querying detailed usage statistics by time interval and associating traffic with the application's unique user ID (UID). The Kotlin/Java host code must efficiently iterate through the returned `NetworkStats.Bucket` objects to sum up received (Rx) and transmitted (Tx) bytes for each application UID, with filtering capabilities based on connectivity type (Wi-Fi or Mobile).

Additionally, the `UsageStatsManager` must be utilized to track app foreground time, which is essential for categorizing network usage into "Foreground" versus "Background" traffic, providing users with the distinction necessary for management and troubleshooting. This requires correlating `UsageEvents` with the NetworkStats time buckets.

##### 2. Real-Time Speed Calculation

Android system APIs do not expose a direct, continuous network speed metric. Therefore, the real-time speed display required for the dashboard must be a calculated metric. The native EventChannel handler, running in a background thread, must implement a continuous polling mechanism using the lower-level `TrafficStats` API.

The process involves:

1.  Reading the total system or per-app Rx/Tx bytes (using `TrafficStats.getTotalRxBytes()` or `getUidRxBytes()`) at an initial time, $T_1$.
2.  Waiting a fixed interval, denoted as $\Delta T$.
3.  Reading the totals again at time $T_2$.
4.  Calculating the differential speed: $(\text{Bytes}_{T2} - \text{Bytes}_{T1}) / \Delta T$.

This calculated transfer rate is then streamed to the Dart side via the EventChannel. Defining a strict rate limit for the polling loop (e.g., 5 times per second) on the native side is critical to balance real-time responsiveness with battery efficiency.

##### 3. Wi-Fi Metrics

Detailed Wi-Fi statistics, such as SSID, signal strength, and connected devices, are accessed using the native `WifiManager`. Note that retrieving location-sensitive data like the connected Wi-Fi SSID often requires the `ACCESS_FINE_LOCATION` runtime permission on modern Android versions, even though the application's core function is network monitoring, not geographic tracking.

#### C. The Illusion of Per-App CPU/Memory Monitoring

The functional requirement to monitor detailed, real-time per-app CPU and memory usage (via `ActivityManager` and `ProcessStats`) presents a significant implementation risk on modern Android devices. Due to enhanced security and privacy policies (API 26 and above), access to such granular resource consumption data for third-party, non-debugged applications is highly restricted or entirely inaccessible.

Attempting to gather this data should be considered a best-effort capability primarily intended for diagnostic purposes within the app itself, rather than a publishable, reliable feature across all Android distributions.

A more reliable and publishable alternative that serves a similar user need is focusing on **Battery Drain**. The application should leverage `BatteryManager` and `PowerManager` APIs to query historic power consumption associated with the application UID. This metric provides a reliable proxy for overall resource intensity—encompassing CPU, memory, and network activity—and can be presented to the user as a clear measure of resource impact.

| API/Service | Purpose | Data Source | Permission/Caveat | Implementation Language |
| :---------- | :------ | :---------- | :---------------- | :---------------------- |
| `NetworkStatsManager` | Detailed per-app data usage (historical) | System Service | `PACKAGE_USAGE_STATS` (Protected) | Kotlin |
| `UsageStatsManager` | App usage time, Foreground/Background state | System Service | `PACKAGE_USAGE_STATS` (Protected) | Kotlin |
| `TrafficStats` | Real-time byte counter for speed calculation | System APIs | Normal Permission (`INTERNET`) | Kotlin |
| `WifiManager` | Wi-Fi configuration details | System Service | `ACCESS_FINE_LOCATION` (Required for SSID/BSSID) | Kotlin |

### III. Persistent Monitoring and Background Service Engineering

Maintaining continuous data monitoring and triggering time-sensitive alerts requires careful selection and configuration of background execution mechanisms, respecting the limitations imposed by the Android operating system to conserve battery life.

#### A. WorkManager for Deferred Data Archival

The `WorkManager` Jetpack library is the recommended solution for persistent tasks that must execute periodically and survive application restarts or system reboots. Its role in NetVigilant is specifically for deferred, non-time-critical operations, such as:

*   Aggregating raw network logs collected over a period (e.g., 24 hours) into optimized summary tables in the local database.
*   Performing routine database maintenance or cleaning up old log entries.
*   Handling optional backend synchronization for long-term stats persistence.

These archival tasks must be defined using a `PeriodicWorkRequest` and rigorously utilize work constraints to minimize energy consumption. Constraints such as `setRequiresCharging(true)` or `setRequiredNetworkType(NetworkType.UNMETERED)` can declaratively ensure the work only runs under optimal conditions, mitigating unnecessary battery drain. The core data acquisition logic (querying `NetworkStatsManager`) must be executed within a dedicated native Kotlin Worker class, as this execution environment provides the necessary system context to access privileged services.

#### B. Foreground Service for Real-Time Alerts and Actions

The core feature of triggering immediate actions based on real-time data thresholds (e.g., automatically disconnecting Wi-Fi or enabling data-saving mode when usage spikes) requires low-latency execution that cannot tolerate the potential deferral inherent in WorkManager.

A **Foreground Service** is mandatory for this continuous, high-frequency network monitoring.

1.  The service must be initialized from the Dart side via a dedicated `MethodChannel` call (e.g., `startContinuousMonitoring(thresholds)`).
2.  It requires a visible, persistent notification in the status bar. This notification is not merely informative; it is a mechanism mandated by the OS to indicate continuous background activity, preventing the OS from terminating the service during periods of inactivity.
3.  The persistent monitoring loop within the Foreground Service feeds the high-frequency EventChannel for UI updates and, crucially, contains the logic to execute native actions when thresholds are breached.

#### C. Battery Optimization Mitigation Strategy

Given the reliance on continuous background execution via a Foreground Service, the application will naturally be targeted by Android’s Doze and App Standby battery optimization features.

To ensure the reliability of real-time monitoring and alerts, requesting an exemption from battery optimization is technically necessary. This involves utilizing the `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission in the manifest.

However, the use of this permission carries the risk of rejection by platform marketplaces or specific OEM policies. Therefore, the strategy must include robust mitigation:

1.  **User Consent and Transparency:** The user must be explicitly informed via a custom dialog why the exemption is required ("to guarantee immediate, accurate data alerts").
2.  **Intent Redirection:** The application should use a dedicated package or native calls to launch the `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` intent, allowing the user to whitelist the application.
3.  **Policy Adherence:** If strict adherence to restrictive policies is paramount, the application should forgo the explicit request and instead direct the user to the overall system battery settings screen (`ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS`), placing the responsibility for continuous function entirely on the user's configuration choices.

#### D. Data Caching and Repository Synchronization

To support the "offline-first" paradigm and decouple the UI from native polling latency, all data access within the Data Layer must prioritize local persistence.

*   **Configuration and Snapshot Caching:** Simple, fast key-value stores (e.g., `Hive` or `SharedPreferences`) should be used for storing user configuration, alert thresholds, and the *most recent* aggregated data snapshot for immediate dashboard display.
*   **Historical Log Storage:** For the massive volume of historical, timestamped usage logs collected by the WorkManager workers, a structured database solution like SQLite (accessed via Room on the Android side) is preferred. Accessing this native database from Dart requires a specialized MethodChannel wrapper that executes the query and serializes the result sets back to Dart.

### IV. Data Visualization, Performance, and UX Optimization

The real-time and historical network data contained within NetVigilant presents significant data visualization and performance challenges. Ensuring a smooth user experience requires adherence to the tight $16\text{ms}$ frame budget and strict implementation of visualization best practices.

#### A. Performance Budgeting and Optimization

Achieving the desired 60fps requires that the application build and render frames within approximately $16\text{ms}$. The high-frequency state updates originating from the native EventChannel are the primary threat to this budget.

1.  **Widget Granularity and Constancy:** The dashboard and data screens must be aggressively factored into the smallest possible `const` widgets. When a high-frequency state stream updates, only the absolute minimal components—such as the digital speed readout—should be rebuilt, rather than forcing a repaint of the entire dashboard layout.
2.  **Asynchronous Data Processing (Isolates):** When the Dart code receives a large data payload from a MethodChannel call (e.g., a query for a month's worth of usage data for 100+ applications), the subsequent task of deserializing the native Map and mapping it into Dart entities can be computationally heavy. If performed on the main UI thread, this process causes jank. Therefore, the implementation must utilize Dart's `compute` isolates (`Isolate.run`) to execute heavy data parsing and mapping operations on a separate CPU core, ensuring the main thread remains unblocked and responsive.
3.  **Profiling Integration:** To proactively identify performance bottlenecks, the finalized application code should incorporate performance tracing hooks (`dart:developer`) for analysis using DevTools (CPU Profiler, Performance View). This enables developers to pinpoint sources of jank, such as unnecessary widget rebuilds or slow layout passes.

#### B. Efficient High-Volume Data Rendering

The App-wise Traffic View and detailed log history screens handle potentially immense data volumes.

1.  **List Virtualization:** For the main list of installed apps, the UI must use performance-optimized rendering techniques like `ListView.builder` or `SliverList`. These widgets implement lazy loading, ensuring that memory consumption and processing time are minimized by only building the widgets currently visible on the screen.
2.  **Pagination:** For extremely long log views (e.g., session-by-session traffic logs), the Data Layer must implement data pagination. Only a fixed subset of records (e.g., 50 entries) should be fetched from the local SQLite store at a time, with subsequent pages loaded asynchronously when the user scrolls near the end of the current list.

#### C. Data Visualization and UX Principles

Effective network monitoring relies on clear, immediate data presentation.

1.  **Clarity and Simplicity:** Mobile dashboard design dictates prioritizing essential data, avoiding clutter, and utilizing simple visuals. Charts should use high-contrast colors and must adhere to mobile-friendly limitations (e.g., limiting bar charts to a digestible number of categories).
2.  **Charting Library Selection:** High-performance charting libraries, such as `fl_chart` or `syncfusion_flutter_charts`, are required to render complex time-series data smoothly.
3.  **Data Aggregation for Visualization:** To prevent the rendering engine from being overwhelmed, the Data Layer must perform necessary aggregation for visualization. For long time spans (e.g., 30-day view), raw timestamps must be summarized into logical buckets (e.g., daily totals or hourly averages). This practice limits the number of data points rendered by the chart widget (e.g., 7 points for a week, 30 points for a month), preserving the 16ms frame budget.

--- 

## Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites

*   Flutter SDK installed (version 3.9.2 or higher recommended).
*   Android SDK with platform tools.
*   A physical Android device or emulator for testing.

### Installation

1.  Clone the repository:
    ```bash
    git clone https://github.com/your_username/netvigilant.git
    cd netvigilant
    ```
2.  Get Flutter packages:
    ```bash
    flutter pub get
    ```
3.  Run the build_runner for code generation (for `freezed`, `json_serializable`, `hive_generator`, `injectable_generator`):
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```
4.  Run the application:
    ```bash
    flutter run
    ```
    Ensure you have an Android device or emulator running.

### Important Note on Permissions

NetVigilant requires special permissions (`PACKAGE_USAGE_STATS`) to function correctly on Android. Upon first launch, the app will guide you through the process of granting these permissions manually in your device settings. Without these permissions, core features will not be available.

--- 

## Roadmap / Future Development

This project benefits from a structured framework for future development and contributions, broken down by architectural modules:

### V. Synthesis: Structured AI Prompt Generation Framework

To transition this specification into actionable code generation, the following framework structures the task by architectural module, ensuring all technical requirements and performance constraints are addressed explicitly.

#### A. Prompt Module 1: Core Domain and Data Models (Dart)

**Objective:** Establish the canonical data entities and interfaces, enforcing immutability and separation of concerns.

1.  **Entity Definition:** Define the immutable Dart data models, including `AppUsageEntity` (for CPU/Memory/Battery proxy stats) and `NetworkTrafficEntity`. The latter must be granular, capturing `txBytes`, `rxBytes`, `timestamp`, `networkType`, and the essential `isBackgroundTraffic` flag.
2.  **Domain Interfaces:** Define the `AbstractNetworkRepository` with signatures for one-time queries (e.g., `Future<Map<String, AppUsageEntity>> getHistoricalAppUsage(...)`) and continuous streaming (`Stream<RealTimeMetricsEntity> getLiveTrafficStream()`), establishing the contract for the Data Layer.

#### B. Prompt Module 2: Native Android Data Acquisition and Event Channel Streaming (Kotlin)

**Objective:** Implement the privileged native access, respecting Android constraints and ensuring background performance.

1.  **Permission Handler:** Generate the native Kotlin code for `PermissionManager` to check for `PACKAGE_USAGE_STATS` status and redirect the user via the `ACTION_USAGE_ACCESS_SETTINGS` intent.
2.  **Network Data Source Implementation:** Generate the `AndroidNetworkDataSource` (Kotlin) which:
    *   Implements the historical query via `NetworkStatsManager`, performing aggregation by UID.
    *   Implements the **Event Stream** logic: A Kotlin Coroutine or background thread loop that polls `TrafficStats.getUidRxBytes()` (at a maximum rate of 5 updates per second) and calculates differential speed, pushing serialized results to the EventSink.
3.  **Background Execution:** Generate the template for a native Android `NetworkMonitorForegroundService` to host the continuous Event Stream logic and handle the persistent notification required for real-time alerting.

#### C. Prompt Module 3: Dart Data Layer Implementation and State Management

**Objective:** Bridge the native layer to Flutter and manage state efficiently.

1.  **Channel Abstraction:** Create Dart wrapper classes (`MethodChannelWrapper` and `EventChannelWrapper`) to manage channel names and basic data serialization.
2.  **Repository Implementation:** Generate the `NetworkRepositoryImplementation`. Crucially, incorporate the optimization requirement: all deserialization and entity mapping for large, historical data payloads received via `MethodChannel` must be executed via `Isolate.run` to prevent main thread blocking and jank.
3.  **State Management:** Define the Riverpod providers: a `StreamProvider` (`realTimeTrafficProvider`) sourced directly from the repository's live stream, and specialized `StateNotifier` classes for managing the aggregated, mutable historical data states used by the dashboard.

#### D. Prompt Module 4: UI and Visualization Implementation (Dart)

**Objective:** Generate performant, user-friendly UI components using best practices.

1.  **Layout:** Generate the `DashboardView` structure utilizing `CustomScrollView` and `SliverList` for smooth scrolling and strict use of the `const` keyword on static components to minimize rebuild costs.
2.  **Real-Time Widgets:** Create a dedicated, lightweight `RealTimeSpeedGauge` widget that listens only to the granular `realTimeTrafficProvider` stream, ensuring minimal screen repaint upon frequent updates.
3.  **Data Lists and Charts:** Generate the `AppTrafficListView` using `ListView.builder` for virtualization. Integrate the `fl_chart` library to render the necessary time-series visualizations (e.g., 7-day bar chart, 24-hour line graph), ensuring the data input to these charts is pre-aggregated to maintain UI performance.

--- 

## Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests. For major changes, please open an issue first to discuss what you would like to change.

## License

This project is licensed under the MIT License - see the LICENSE file for details.