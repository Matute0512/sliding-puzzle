import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keyProperties = Properties()
val keyPropertiesFile = rootProject.file("key.properties")
if (keyPropertiesFile.exists()) {
    keyProperties.load(keyPropertiesFile.inputStream())
}

// Firma del release: se prefiere el entorno (CI) y se cae a android/key.properties.
// Si no hay ninguna fuente, la config de firma no se crea y el release build usa
// la firma por defecto (solo para validar el build; NO para producción).
val releaseKeyAlias = System.getenv("KEY_ALIAS") ?: keyProperties.getProperty("keyAlias")
val releaseKeyPassword = System.getenv("KEY_PASSWORD") ?: keyProperties.getProperty("keyPassword")
val releaseStorePassword = System.getenv("KEY_STORE_PASSWORD") ?: keyProperties.getProperty("storePassword")
val releaseStoreFile = System.getenv("KEY_STORE_FILE") ?: keyProperties.getProperty("storeFile")

android {
    namespace = "dev.matute.slidingpuzzle"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        if (releaseKeyAlias != null && releaseKeyPassword != null && releaseStorePassword != null && releaseStoreFile != null) {
            create("release") {
                this.keyAlias = releaseKeyAlias
                this.keyPassword = releaseKeyPassword
                this.storePassword = releaseStorePassword
                this.storeFile = file(releaseStoreFile)
            }
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "dev.matute.slidingpuzzle"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Firma real si hay key.properties/env vars; si no, debug (solo validación).
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
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
