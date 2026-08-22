import java.io.FileInputStream
import java.util.Properties

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.kotlin.serialization)
    alias(libs.plugins.ksp)
    alias(libs.plugins.hilt)
}

// Release signing is read from an untracked keystore.properties (see README).
// When it is absent (e.g. CI or a fresh clone) the release build stays unsigned
// instead of failing, so the project still configures.
val keystorePropsFile = rootProject.file("keystore.properties")
val keystoreProps = Properties().apply {
    if (keystorePropsFile.exists()) load(FileInputStream(keystorePropsFile))
}
val hasReleaseSigning = keystorePropsFile.exists()

// ── Versi aplikasi — SATU-SATUNYA tempat untuk dinaikkan tiap rilis ─────────
// Naikkan angka di bawah setiap ada update:
//   • perbaikan kecil / konten  → patch  (1.0.0 → 1.0.1)
//   • fitur baru                → minor  (1.0.1 → 1.1.0), patch balik ke 0
//   • perubahan besar           → major  (1.9.0 → 2.0.0), minor & patch ke 0
// versionName = "major.minor.patch" (tampil di Play Store & di app).
// versionCode dihitung otomatis dan DIJAMIN selalu naik — Google mewajibkan
// versionCode lebih besar dari upload sebelumnya untuk tiap rilis ke Play Store.
val appVersionMajor = 1
val appVersionMinor = 5
val appVersionPatch = 1
val appVersionName = "$appVersionMajor.$appVersionMinor.$appVersionPatch"
val appVersionCode = appVersionMajor * 10000 + appVersionMinor * 100 + appVersionPatch

// Room writes the schema of every database version here. Commit these files:
// they are the reference a future Migration is written and tested against.
ksp {
    arg("room.schemaLocation", "$projectDir/schemas")
}

android {
    namespace = "com.ichigo.app"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.ichigo.app"
        minSdk = 24
        targetSdk = 35
        versionCode = appVersionCode
        versionName = appVersionName

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        vectorDrawables { useSupportLibrary = true }
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = rootProject.file(keystoreProps["storeFile"] as String)
                storePassword = keystoreProps["storePassword"] as String
                keyAlias = keystoreProps["keyAlias"] as String
                keyPassword = keystoreProps["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // R8: strip unused code and obfuscate everything not explicitly kept
            // in proguard-rules.pro, so a decompiled APK reads as meaningless
            // symbols instead of the real business logic.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            if (hasReleaseSigning) signingConfig = signingConfigs.getByName("release")
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
    buildFeatures {
        compose = true
        buildConfig = true
    }
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }

    // Name the built artifacts "IchiGo-<version>" instead of "app-release".
    applicationVariants.all {
        val variant = this
        outputs.all {
            (this as com.android.build.gradle.internal.api.BaseVariantOutputImpl)
                .outputFileName = "IchiGo-${variant.versionName}.apk"
        }
    }
}

// Base name for the App Bundle output → "IchiGo-release.aab".
base { archivesName.set("IchiGo") }

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(libs.androidx.lifecycle.runtime.compose)
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.core.splashscreen)

    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.ui)
    implementation(libs.androidx.ui.graphics)
    implementation(libs.androidx.ui.tooling.preview)
    implementation(libs.androidx.material3)
    implementation(libs.androidx.material.icons.extended)
    implementation(libs.androidx.material3.window.size)
    implementation(libs.androidx.ui.text.google.fonts)
    debugImplementation(libs.androidx.ui.tooling)

    implementation(libs.androidx.navigation.compose)

    implementation(libs.hilt.android)
    ksp(libs.hilt.compiler)
    implementation(libs.hilt.navigation.compose)

    implementation(libs.room.runtime)
    implementation(libs.room.ktx)
    ksp(libs.room.compiler)

    implementation(libs.androidx.datastore.preferences)
    implementation(libs.androidx.work.runtime)
    implementation(libs.kotlinx.serialization.json)
    implementation(libs.kotlinx.coroutines.android)
    implementation(libs.play.services.auth)
    implementation(libs.okhttp)

    testImplementation(libs.junit)
    testImplementation(libs.kotlinx.coroutines.test)
    androidTestImplementation(libs.androidx.junit)
    androidTestImplementation(libs.androidx.espresso.core)
    androidTestImplementation(platform(libs.androidx.compose.bom))
}
