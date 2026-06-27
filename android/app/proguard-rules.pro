# ==============================================================================
# KhataFlow – ProGuard / R8 Rules
# ==============================================================================
# These rules prevent R8 from stripping classes that are accessed via
# reflection or JNI at runtime (Flutter engine, Isar, local_auth, share_plus).
# ==============================================================================

# ── Flutter Engine ─────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# ── Isar Database (native JNI bindings) ───────────────────────────────────────
-keep class dev.isar.** { *; }
-keep class io.objectbox.** { *; }
-dontwarn dev.isar.**

# ── Flutter Local Auth (uses AndroidX Biometric) ──────────────────────────────
-keep class androidx.biometric.** { *; }
-keep class io.flutter.plugins.localauth.** { *; }
-dontwarn androidx.biometric.**

# ── Share Plus ─────────────────────────────────────────────────────────────────
-keep class dev.fluttercommunity.plus.share.** { *; }
-dontwarn dev.fluttercommunity.plus.share.**

# ── Flutter Secure Storage ─────────────────────────────────────────────────────
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-dontwarn com.it_nomads.fluttersecurestorage.**

# ── Flutter Local Notifications ────────────────────────────────────────────────
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# ── Path Provider ──────────────────────────────────────────────────────────────
-keep class io.flutter.plugins.pathprovider.** { *; }

# ── AndroidX & Support Libraries ──────────────────────────────────────────────
-keep class androidx.core.** { *; }
-keep class androidx.lifecycle.** { *; }
-dontwarn androidx.window.**

# ── Kotlin Coroutines ─────────────────────────────────────────────────────────
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory { *; }
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler { *; }
-dontwarn kotlinx.coroutines.**

# ── Kotlin Serialization ──────────────────────────────────────────────────────
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt
-keepclassmembers class kotlinx.serialization.json.** { *** Companion; }

# ── Gson / JSON (if used internally by plugins) ───────────────────────────────
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# ── General R8 stability ──────────────────────────────────────────────────────
# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
# Keep Parcelable classes
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator CREATOR;
}
# Keep enum members
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
# Keep R classes
-keepclassmembers class **.R$* {
    public static <fields>;
}

# ── Suppress noisy warnings from third-party libs ─────────────────────────────
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
-dontwarn javax.annotation.**
-dontwarn com.google.android.gms.**
