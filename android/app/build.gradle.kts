import groovy.json.JsonSlurper
import java.security.KeyStore
import java.security.MessageDigest

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.nalara"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.nalara"
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

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:35.0.0"))
    implementation("com.google.firebase:firebase-analytics")
}

// A fresh clone uses that developer's signing key, not the original author's.
// Detect missing OAuth registration before distributing an APK that cannot log in.
android.buildTypes.configureEach {
    val buildType = this
    val suffix = name.replaceFirstChar { it.uppercaseChar() }
    val checkGoogle = tasks.register("checkGoogleSignIn$suffix") {
        group = "verification"
        description = "Checks this build's signing certificate against google-services.json."
        dependsOn("validateSigning$suffix")
        doLast {
            val signing = buildType.signingConfig
                ?: throw GradleException("Signing config is missing for ${buildType.name}.")
            val storeFile = signing.storeFile
                ?: throw GradleException("Signing keystore is missing for ${buildType.name}.")
            val store = KeyStore.getInstance(storeFile, signing.storePassword!!.toCharArray())
            val certificate = store.getCertificate(signing.keyAlias)
                ?: throw GradleException("Signing certificate is missing for ${buildType.name}.")
            fun fingerprint(algorithm: String) = MessageDigest.getInstance(algorithm)
                .digest(certificate.encoded).joinToString(":") { "%02X".format(it) }
            val sha1 = fingerprint("SHA-1")
            val sha256 = fingerprint("SHA-256")
            val packageName = android.defaultConfig.applicationId +
                (buildType.applicationIdSuffix ?: "")
            logger.lifecycle("Google Sign-In (${buildType.name}): $packageName\nSHA-1: $sha1\nSHA-256: $sha256")

            val configFile = file("google-services.json")
            if (!configFile.exists()) {
                throw GradleException("Download google-services.json from Firebase into android/app/.")
            }
            val config = JsonSlurper().parse(configFile) as Map<*, *>
            val clients = config["client"] as? List<*> ?: emptyList<Any>()
            val client = clients.filterIsInstance<Map<*, *>>().firstOrNull {
                val info = it["client_info"] as? Map<*, *>
                val androidInfo = info?.get("android_client_info") as? Map<*, *>
                androidInfo?.get("package_name") == packageName
            } ?: throw GradleException("No Firebase Android app for $packageName in google-services.json.")
            val oauthClients = (client["oauth_client"] as? List<*>)
                .orEmpty().filterIsInstance<Map<*, *>>()
            if (oauthClients.none { (it["client_type"] as? Number)?.toInt() == 3 }) {
                throw GradleException("Enable Google authentication in Firebase and download google-services.json with a web OAuth client (type 3).")
            }
            val registered = oauthClients.any {
                val info = it["android_info"] as? Map<*, *>
                (it["client_type"] as? Number)?.toInt() == 1 &&
                    info?.get("package_name") == packageName &&
                    (info["certificate_hash"] as? String)?.replace(":", "")
                        .equals(sha1.replace(":", ""), ignoreCase = true)
            }
            if (!registered) {
                throw GradleException(
                    """
                    Google Sign-In: SHA-1 komputer pembuat APK belum ada dalam google-services.json.
                    Tambahkan SHA-1 dan SHA-256 di atas melalui Firebase Console > Project settings > $packageName > Add fingerprint.
                    Lalu unduh ulang google-services.json ke android/app/ dan jalankan build kembali.
                    Jangan mengganti certificate_hash secara manual atau membagikan debug.keystore.
                    Panduan: docs/google-sign-in-team.md
                    """.trimIndent()
                )
            }
            logger.lifecycle("Google Sign-In: signing certificate matches the local Firebase configuration.")
        }
    }
    tasks.matching { it.name == "process${suffix}GoogleServices" }.configureEach {
        dependsOn(checkGoogle)
    }
}
