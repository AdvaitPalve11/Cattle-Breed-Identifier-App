# Minimal ProGuard rules to satisfy R8
# Keep the application class and any classes referenced by reflection if needed
-keep class com.example.** { *; }
# Keep Flutter plugin registrant
-keep class io.flutter.plugins.** { *; }
# Keep native library loaders
-keepclassmembers class * {
    native <methods>;
}
# Prevent obfuscation of classes annotated for serialization (add as needed)
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
# End of file
