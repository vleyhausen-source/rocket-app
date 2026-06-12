# =============================================================================
# ProGuard / R8 Regeln fuer Rocket Rise
# Angewendet nur auf Release-Builds (minifyEnabled = true)
# =============================================================================

# --- Flutter / Dart ---
# Flutter-Engine-Klassen behalten (die JNI-Bridge darf nicht umbenannt werden)
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-dontwarn io.flutter.**

# Dart-generierte Klassen und Entrypoints behalten
-keep class com.vleyhausen.rocketrise.** { *; }
-keep class com.vleyhausen.rocketrise.MainActivity { *; }

# --- Google Mobile Ads (AdMob) ---
# Offizielle AdMob ProGuard-Regeln
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-dontwarn com.google.android.gms.ads.**
# UMP (User Messaging Platform) fuer DSGVO
-keep class com.google.android.ump.** { *; }
-dontwarn com.google.android.ump.**

# --- Google Play Services ---
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# --- WebView (benoetigt fuer AdMob Consent-Dialog) ---
-keep class androidx.webkit.** { *; }
-keep class android.webkit.** { *; }
-dontwarn androidx.webkit.**

# --- Flame Engine ---
# Flame nutzt keine direkte Java-Reflexion, aber seine Abhängigkeiten (audioplayers) schon
-keep class xyz.luan.audioplayers.** { *; }
-dontwarn xyz.luan.audioplayers.**

# --- audioplayers / SoundPool ---
-keep class com.ryanheise.** { *; }
-dontwarn com.ryanheise.**

# --- SharedPreferences ---
# Keine speziellen Regeln noetig (Android-Systemdienst)

# --- Root Detection ---
# flutter_jailbreak_detection wurde entfernt (AGP 9.x inkompatibel).
# Root-Detection erfolgt nativ via dart:io in security_service.dart – keine ProGuard-Regeln noetig.

# --- androidx.work (WorkManager) ---
# Wird transitiv durch play-services-ads gezogen. R8 darf WorkerFactory und
# Configuration.Provider NICHT umbenennen, sonst crasht die WorkDatabase-Initialisierung.
-keep class androidx.work.** { *; }
-keep interface androidx.work.** { *; }
-dontwarn androidx.work.**

# --- androidx.startup (App Startup Library) ---
# InitializationProvider wird via Manifest-Merger eingebaut; R8 darf den Eintrag nicht entfernen.
-keep class androidx.startup.** { *; }
-keep interface androidx.startup.** { *; }
-dontwarn androidx.startup.**

# --- androidx.room (Room Database) ---
# Wird von work-runtime benoetigt (WorkDatabase). R8 darf Room-Entities und DAOs nicht strippten.
-keep class androidx.room.** { *; }
-keep interface androidx.room.** { *; }
-dontwarn androidx.room.**
-keepclassmembers @androidx.room.Entity class * { *; }
-keepclassmembers @androidx.room.Dao interface * { *; }

# --- Allgemeine Sicherheitsregeln ---
# Stack-Traces lesbar halten fuer Crashlytics (spaeter)
-keepattributes SourceFile,LineNumberTable
# Annotationen behalten (benoetigt fuer Reflection)
-keepattributes *Annotation*
# Generics behalten
-keepattributes Signature
# Exceptions vollstaendig behalten
-keepattributes Exceptions

# --- Logging in Release entfernen ---
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
