Android Build Configuration

This Android project uses modern tooling that matches Flutter's recommendations:

Toolchain Versions:
- Android Gradle Plugin (AGP): 8.6.0
- Kotlin: 2.1.0
- Gradle: 8.7
- JDK: 17 (tested with Eclipse Temurin/Adoptium)

Required Setup:
1. Install JDK 17 (Eclipse Temurin/Adoptium recommended)
2. Set Android Studio's Gradle JVM:
   - File → Settings (Preferences on macOS)
   - Build, Execution, Deployment → Build Tools → Gradle
   - Set "Gradle JVM" to JDK 17
   - Click "Sync Project with Gradle Files"

Build Commands:
```bash
# Production APK build
flutter build apk --release

# Production App Bundle (AAB) build
flutter build appbundle
```

Project Configuration:
- Uses modern Android namespace declarations
- R8 optimizations enabled with minimal ProGuard rules
- AndroidX enabled, Jetifier disabled
- Gradle JVM pinned to JDK 17 via `org.gradle.java.home`
- Duplicate SDK cmdline-tools removed for clean builds

Troubleshooting:
- If Android Studio shows different JVM warnings than CLI builds, verify the IDE's Gradle JVM matches `org.gradle.java.home` in `gradle.properties`
- For clean builds, use `./gradlew clean assembleRelease`
- Check logcat or build output with `--warning-mode all` for detailed diagnostics
