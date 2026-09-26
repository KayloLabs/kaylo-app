import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The Flutter tool hands Gradle every --dart-define as a comma-separated
// list of base64 "KEY=VALUE" entries. Decoding it here lets one flag
// (GOOGLE_MAPS_API_KEY) configure the Dart side and the Android manifest.
val dartDefines: Map<String, String> =
    (project.findProperty("dart-defines") as String?)
        ?.split(",")
        ?.filter { it.isNotBlank() }
        ?.mapNotNull { encoded ->
            val decoded = runCatching {
                String(Base64.getDecoder().decode(encoded), Charsets.UTF_8)
            }.getOrNull() ?: return@mapNotNull null
            val separator = decoded.indexOf('=')
            if (separator > 0) {
                decoded.substring(0, separator) to decoded.substring(separator + 1)
            } else {
                null
            }
        }
        ?.toMap()
        ?: emptyMap()

val localProperties = Properties().apply {
    val file = rootProject.file("local.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

// Google Maps key for the location picker. The dart-define wins; a line
// in local.properties (gitignored) suits builds from Android Studio.
val googleMapsApiKey: String =
    dartDefines["GOOGLE_MAPS_API_KEY"]
        ?: localProperties.getProperty("GOOGLE_MAPS_API_KEY")
        ?: (project.findProperty("GOOGLE_MAPS_API_KEY") as String?)
        ?: System.getenv("GOOGLE_MAPS_API_KEY")
        ?: ""

android {
    namespace = "com.kaylo.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.kaylo.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = googleMapsApiKey
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
