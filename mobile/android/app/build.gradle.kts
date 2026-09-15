import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Real release signing (android/key.properties, gitignored - see
// android/.gitignore) - required for Play Console uploads, which reject
// the debug-signed builds used for direct-sideload testing. Falls back to
// null (and thus the debug config below) when key.properties doesn't
// exist, so local `flutter run`/sideload builds keep working without it.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseSigning = keystorePropertiesFile.exists()
if (hasReleaseSigning) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.ethioserve.ethioserve"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.ethioserve.ethioserve"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Real signing when android/key.properties exists (see above -
            // required for Play Console uploads); falls back to the debug
            // keys otherwise, so `flutter run --release`/direct-sideload
            // builds keep working without needing the release keystore.
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }

    // AGP's "lint vital" task runs on every release build by default and
    // blocks the build entirely if it can't resolve any of its own
    // lint-checks dependencies - confirmed live: it failed trying to fetch
    // com.google.android.gms:play-services-tapandpay:17.1.2, a transitive
    // lint-only dependency of stripe_android's Tap-to-Pay support (a
    // feature this app doesn't use), not an actual problem with our code.
    // `flutter analyze` is this project's real lint gate (mobile-ci.yml);
    // this only stops that unrelated, unresolvable dependency from being
    // able to block a release/App Bundle build.
    lint {
        checkReleaseBuilds = false
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
