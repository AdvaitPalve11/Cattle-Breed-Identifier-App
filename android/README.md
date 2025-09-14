Android build notes

This repository made a few project-specific Android toolchain choices to keep builds stable across machines and avoid known issues:

- JDK: Use Temurin / Adoptium JDK 17. Example path used here:
  `C:\Program Files\Eclipse Adoptium\jdk-17.0.16.8-hotspot`

- Gradle wrapper: pinned to Gradle 8.7 (see `android/gradle/wrapper/gradle-wrapper.properties`).

- Android Gradle Plugin (AGP): plugin version set in `android/settings.gradle.kts` (currently 8.2.1).

- Jetifier: disabled in `android/gradle.properties` (`android.enableJetifier=false`). Jetifier is legacy AndroidX migration tooling; when possible prefer updating libraries to AndroidX and keep Jetifier off.

- Pin Gradle JVM: `android/gradle.properties` contains `org.gradle.java.home` pointing to the JDK 17 used for builds. This forces Gradle daemons to run with the pinned JDK rather than a possibly incompatible Android Studio JBR.

Troubleshooting quick steps

1. Ensure `JAVA_HOME` points to a JDK 17 installation.
2. In the project `android` folder, stop Gradle daemons so they pick up the JVM change:

```powershell
cd android
.\gradlew.bat --stop
```

3. Run a build and examine verbose output if necessary:

```powershell
flutter pub get
flutter build apk -v
```

If you need help upgrading AGP/Gradle further for the latest Flutter tooling, I can prepare a PR with tested version bumps and follow-up changes.
