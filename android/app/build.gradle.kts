import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// key.properties einlesen (lokal vorhanden oder via CI-Step erzeugt)
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
val hasSigningConfig = keyPropertiesFile.exists()
if (hasSigningConfig) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

android {
    namespace = "com.vleyhausen.rocketrise"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        create("release") {
            if (hasSigningConfig) {
                storeFile = keyPropertiesFile.parentFile.resolve(
                    keyProperties["storeFile"] as String
                )
                storePassword = keyProperties["storePassword"] as String
                keyAlias = keyProperties["keyAlias"] as String
                keyPassword = keyProperties["keyPassword"] as String
            }
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.vleyhausen.rocketrise"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = 39
        versionName = "1.0.37"
    }

    buildTypes {
        release {
            // Release-Signing wenn key.properties vorhanden, sonst debug (lokale Entwicklung)
            signingConfig = if (hasSigningConfig) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            // Code-Verkleinerung & Verschleierung mit R8
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// Erzwingt eine einheitliche androidx.work Version um den WorkDatabase-Crash zu beheben.
// Ursache: play-services-ads (via google_mobile_ads) zieht work-runtime:2.7.0 rein,
// was mit neueren fragment/startup Versionen inkompatibel ist und beim App-Start crasht.
configurations.all {
    resolutionStrategy {
        force("androidx.work:work-runtime:2.9.1")
        force("androidx.work:work-runtime-ktx:2.9.1")
    }
}
