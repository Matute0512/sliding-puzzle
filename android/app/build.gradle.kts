import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
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

// Lee ADMOB_APP_ID_ANDROID desde ../dart_defines.json (ignorado en git) o desde
// variables de entorno en CI. Si ninguno está presente, usa el App ID de prueba
// oficial de Google para que el proyecto compile sin exponer IDs reales en git.
fun resolveAdmobAppId(): String {
    val envId = System.getenv("ADMOB_APP_ID_ANDROID")?.trim()
    if (!envId.isNullOrEmpty()) return envId

    val definesFile = rootProject.file("../dart_defines.json")
    if (definesFile.exists()) {
        val regex = Regex(""""ADMOB_APP_ID_ANDROID"\s*:\s*"([^"]+)"""")
        val match = regex.find(definesFile.readText())
        val fileId = match?.groupValues?.getOrNull(1)?.trim()
        if (!fileId.isNullOrEmpty()) return fileId
    }
    return "ca-app-pub-3940256099942544~3347511713"
}

// Lee PLAY_GAMES_APP_ID desde ../dart_defines.json o desde variables de entorno
// en CI. Si no está presente, devuelve "0" para compilar sin exponer IDs en git.
fun resolvePlayGamesAppId(): String {
    val envId = System.getenv("PLAY_GAMES_APP_ID")?.trim()
    if (!envId.isNullOrEmpty()) return envId

    val definesFile = rootProject.file("../dart_defines.json")
    if (definesFile.exists()) {
        val regex = Regex(""""PLAY_GAMES_APP_ID"\s*:\s*"([^"]+)"""")
        val match = regex.find(definesFile.readText())
        val fileId = match?.groupValues?.getOrNull(1)?.trim()
        if (!fileId.isNullOrEmpty()) return fileId
    }
    return "0"
}

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

    buildFeatures {
        resValues = true
    }

    defaultConfig {
        applicationId = "dev.matute.slidingpuzzle"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["admobAppId"] = resolveAdmobAppId()
        resValue("string", "game_services_project_id", resolvePlayGamesAppId())
    }

    buildTypes {
        release {
            // Firma real si hay key.properties/env vars; si no, debug (solo validación).
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
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
