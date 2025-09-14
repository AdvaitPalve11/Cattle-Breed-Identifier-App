# cattle_breed_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Android toolchain (project-specific notes)

This project requires a consistent Android toolchain across developers and CI. During builds I pinned Gradle to use a system JDK 17 and disabled Jetifier to avoid runtime transform issues with modern dependencies.

- JDK: AdoptOpenJDK / Temurin 17 (example path used in this repo):
	`C:\\Program Files\\Eclipse Adoptium\\jdk-17.0.16.8-hotspot`
- Gradle wrapper: 8.7 (configured in `android/gradle/wrapper/gradle-wrapper.properties`)
- Android Gradle Plugin (AGP): 8.2.1 (configured in `android/settings.gradle.kts` plugins block)
- Jetifier: disabled (`android/gradle.properties`: `android.enableJetifier=false`). Most modern plugins and libraries are AndroidX-ready; disabling Jetifier avoids a Jetify transform error seen when mixing toolchains.

If you run into build errors related to Java versions, ensure your system's `JAVA_HOME` points to JDK 17 and run `cd android && .\\gradlew.bat --stop` to restart Gradle daemons.
