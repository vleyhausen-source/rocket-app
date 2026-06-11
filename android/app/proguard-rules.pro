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

# --- Root Detection (flutter_jailbreak_detection) ---
-keep class com.Changenode.flutter_jailbreak_detection.** { *; }
-dontwarn com.Changenode.flutter_jailbreak_detection.**

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
