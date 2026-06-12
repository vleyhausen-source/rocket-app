# =============================================================================
# ProGuard / R8 Regeln fuer Rocket Rise
# Angewendet nur auf Release-Builds (minifyEnabled = true)
# =============================================================================

# --- Flutter / Dart ---
# Flutter-Engine-Klassen behalten (JNI-Bridge darf nicht umbenannt werden)
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-dontwarn io.flutter.**

# Dart-generierte Klassen und Entrypoints behalten
-keep class com.vleyhausen.rocketrise.** { *; }
-keep class com.vleyhausen.rocketrise.MainActivity { *; }

# GeneratedPluginRegistrant wird zur Laufzeit dynamisch geladen –
# ohne explizite Keep-Rule entfernt R8 die Klasse weil sie "ungenutzt" wirkt.
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# =============================================================================
# Plugin-Klassen aus GeneratedPluginRegistrant.java (alle explizit behalten)
# =============================================================================

# audioplayers
-keep class xyz.luan.audioplayers.** { *; }
-dontwarn xyz.luan.audioplayers.**

# google_mobile_ads Plugin-Registrant
-keep class io.flutter.plugins.googlemobileads.** { *; }
-dontwarn io.flutter.plugins.googlemobileads.**

# JNI / dart:ffi Bindings (Klassen werden via Reflection zur Laufzeit gesucht!)
# Ohne Keep: ClassNotFoundException im Release-Build, da R8 sie als ungenutzt entfernt.
# consumer-rules.pro der jni/jni_flutter Packages enthalten diese Regeln,
# aber wir duplizieren sie hier als Sicherheitsnetz.
-keep class com.github.dart_lang.jni.** { *; }
-keep class com.github.dart_lang.jni_flutter.** { *; }
-dontwarn com.github.dart_lang.jni.**
-dontwarn com.github.dart_lang.jni_flutter.**

# SharedPreferences Plugin
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-dontwarn io.flutter.plugins.sharedpreferences.**

# WebView Flutter Plugin (benoetigt fuer AdMob Consent-Form)
-keep class io.flutter.plugins.webviewflutter.** { *; }
-dontwarn io.flutter.plugins.webviewflutter.**

# com.ryanheise (audioplayers Dienste)
-keep class com.ryanheise.** { *; }
-dontwarn com.ryanheise.**

# =============================================================================
# Google Mobile Ads (AdMob) + UMP
# =============================================================================

# Offizielle AdMob ProGuard-Regeln
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# UMP (User Messaging Platform) fuer DSGVO
# WICHTIG: UMP-Klassen werden via Reflection aufgerufen (C++/JNI-Bridge).
# Ohne diese Regel: stille Initialisierungsfehler → schwarzer Bildschirm.
-keep class com.google.android.ump.** { *; }
-keepclassmembers class com.google.android.ump.** { *; }
-dontwarn com.google.android.ump.**

# Consent-Form Activity und Receivers duerfen nicht umbenannt werden
-keep public class com.google.android.ump.ConsentInformation
-keep public class com.google.android.ump.ConsentForm
-keep public class com.google.android.ump.ConsentRequestParameters
-keep public class com.google.android.ump.UserMessagingPlatform

# =============================================================================
# Google Play Services
# =============================================================================

-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# =============================================================================
# WebView (benoetigt fuer AdMob Consent-Dialog)
# =============================================================================

-keep class androidx.webkit.** { *; }
-keep class android.webkit.** { *; }
-dontwarn androidx.webkit.**

# =============================================================================
# Kotlin
# =============================================================================

# kotlin.Metadata MUSS erhalten bleiben – R8 entfernt sie sonst und bricht
# alle Reflection-basierten Bibliotheken (Riverpod-Internals, Coroutines etc.)
-keepattributes kotlin.Metadata
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**

# Kotlin Coroutinen (werden von google_mobile_ads + audioplayers genutzt)
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# Kotlin Companion Objects behalten (R8 entfernt sie ohne explizite Regel)
-keepclassmembers class * {
    @kotlin.jvm.JvmStatic *;
}

# =============================================================================
# androidx
# =============================================================================

# WorkManager (transitiv durch play-services-ads gezogen)
# WorkerFactory und Configuration.Provider duerfen nicht umbenannt werden
-keep class androidx.work.** { *; }
-keep interface androidx.work.** { *; }
-dontwarn androidx.work.**

# App Startup Library (InitializationProvider via Manifest)
-keep class androidx.startup.** { *; }
-keep interface androidx.startup.** { *; }
-dontwarn androidx.startup.**

# Room Database (von work-runtime benoetigt)
-keep class androidx.room.** { *; }
-keep interface androidx.room.** { *; }
-dontwarn androidx.room.**
-keepclassmembers @androidx.room.Entity class * { *; }
-keepclassmembers @androidx.room.Dao interface * { *; }

# Activity (EdgeToEdge, ComponentActivity)
-keep class androidx.activity.** { *; }
-dontwarn androidx.activity.**

# =============================================================================
# Debug-Attribute fuer Crash-Reports
# =============================================================================

# Stack-Traces lesbar halten
-keepattributes SourceFile,LineNumberTable
# Annotationen behalten (benoetigt fuer Reflection)
-keepattributes *Annotation*
# Generics behalten
-keepattributes Signature
# Exceptions vollstaendig behalten
-keepattributes Exceptions
# Inner Classes behalten (benoetigt fuer anonyme Klassen in Callbacks)
-keepattributes InnerClasses,EnclosingMethod

# =============================================================================
# WICHTIG: KEIN -assumenosideeffects fuer android.util.Log !
# =============================================================================
#
# -assumenosideeffects class android.util.Log { ... } ist in Flutter-Apps
# GEFAEHRLICH: R8 propagiert diese Regel rueckwaerts durch den Call-Graph und
# kann Initialisierungs-Code in UMP/AdMob-Bibliotheken entfernen, der intern
# Log.d()-Aufrufe enthaelt. Das Ergebnis: stille Initialisierungsfehler und
# schwarzer Bildschirm auf dem Gerät (genau das Problem mit Xiaomi HyperOS).
#
# Log-Entfernung ist in Flutter-Release-APKs ohnehin minimal relevant weil
# Dart's debugPrint() im Release-Modus automatisch ein No-Op wird.
# Auf Android-Ebene ist android.util.Log in Release-Builds meist deaktiviert
# (BuildConfig.DEBUG = false) – R8-Stripping bringt kaum Groessenvorteil.
