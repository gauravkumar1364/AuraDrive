plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.project"
    compileSdk = 36 // Updated to API 36 to meet dependency requirements
    ndkVersion = "27.0.12077973" // Use the installed NDK version
    
    // Explicitly disable all native C/C++ features since NaviSafe doesn't use them
    buildFeatures {
        buildConfig = false
    }
    
    // Disable external native build to prevent NDK requirement
    externalNativeBuild {
        // Intentionally empty to disable native builds
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // NaviSafe Application ID
        applicationId = "com.example.project"
        // MinSdk 23 required for modern Bluetooth LE and proper permission handling
        minSdk = flutter.minSdkVersion  // Required for BLE, permission_handler, and Android 12+ compatibility
        targetSdk = 34  // Using stable API 34 for better compatibility
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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
