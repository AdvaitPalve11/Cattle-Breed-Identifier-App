# Cattle Breed Identifier App

This Flutter application helps farmers and cattle enthusiasts identify the breed of a cow or buffalo from a photo. It uses a local TensorFlow Lite model for fast, offline-first image classification and provides information about the identified breed.

## Features

- **Image-Based Breed Identification**: Upload a photo from the gallery or take a new one with the camera.
- **Local Machine Learning Model**: Uses an on-device TFLite model for breed classification, so it works without an internet connection.
- **History**: Saves past predictions with images and confidence scores for later review (using a local database).
- **Multi-language Support**: Includes localization for different languages.

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- An editor like [VS Code](https://code.visualstudio.com/) or [Android Studio](https://developer.android.com/studio).

### Installation

1.  **Clone the repository:**
    ```sh
    git clone https://github.com/your-username/cattle_breed_app.git
    # Note: Replace "your-username" with your actual GitHub username or organization.
    cd cattle_breed_app
    ```

2.  **Install dependencies:**
    ```sh
    flutter pub get
    ```

3.  **Run the app:**
    ```sh
    flutter run
    ```

## Android toolchain (project-specific notes)

This project requires a consistent Android toolchain across developers and CI. During builds I pinned Gradle to use a system JDK 17 and disabled Jetifier to avoid runtime transform issues with modern dependencies.

- JDK: AdoptOpenJDK / Temurin 17 (example path used in this repo):
  `C:\\Program Files\\Eclipse Adoptium\\jdk-17.0.16.8-hotspot`
- Gradle wrapper: 8.7 (configured in `android/gradle/wrapper/gradle-wrapper.properties`)
- Android Gradle Plugin (AGP): 8.6.0 (configured in `android/settings.gradle.kts` plugins block)
- Jetifier: disabled (`android/gradle.properties`: `android.enableJetifier=false`). Most modern plugins and libraries are AndroidX-ready; disabling Jetifier avoids a Jetify transform error seen when mixing toolchains.

If you run into build errors related to Java versions, ensure your system's `JAVA_HOME` points to JDK 17 and run `cd android && .\\gradlew.bat --stop` to restart Gradle daemons.
