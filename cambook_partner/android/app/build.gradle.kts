import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// ── 读取 keystore 签名配置（release 打包时使用）──────────────────────
// 在 android/key.properties 中配置（不提交到 Git）：
//   storeFile=../your.keystore
//   storePassword=xxx
//   keyAlias=xxx
//   keyPassword=xxx
val keyPropsFile = rootProject.file("key.properties")
val keyProps = Properties()
if (keyPropsFile.exists()) {
    keyProps.load(FileInputStream(keyPropsFile))
}

android {
    namespace = "com.cambook.partner"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "29.0.13846066"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // ── 签名配置 ────────────────────────────────────────────────────
    signingConfigs {
        create("release") {
            if (keyPropsFile.exists()) {
                storeFile     = file(keyProps["storeFile"]    as String)
                storePassword = keyProps["storePassword"]     as String
                keyAlias      = keyProps["keyAlias"]          as String
                keyPassword   = keyProps["keyPassword"]       as String
            }
        }
    }

    defaultConfig {
        minSdk     = flutter.minSdkVersion
        targetSdk  = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ── 多商户 Flavor ─────────────────────────────────────────────
    // 每新增一个商户，在此块添加对应的 flavor 即可。
    // applicationId 对应各商户在 Google Play 的唯一包名。
    flavorDimensions += "merchant"

    productFlavors {
        // 默认商户（CamBook）
        create("cambook") {
            dimension     = "merchant"
            applicationId = "com.cambook.partner"
            resValue("string", "app_name", "CamBook Partner")
        }
        // 商户 B 示例（SpaVibe）
        create("spavibe") {
            dimension     = "merchant"
            applicationId = "com.spavibe.partner"
            resValue("string", "app_name", "SpaVibe Partner")
        }
    }

    buildTypes {
        release {
            signingConfig = if (keyPropsFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled   = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
