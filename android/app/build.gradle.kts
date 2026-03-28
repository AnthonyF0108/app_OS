plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Aplica o plugin sem repetir a versão
}

android {
    namespace = "com.anthony.ordemservico" // Verifique se este é o seu namespace real
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
        // MUITO IMPORTANTE: Este ID deve ser IGUAL ao do seu Console Firebase
        applicationId = "com.anthony.ordemservico"
        minSdk = flutter.minSdkVersion // Recomendado para Firebase e Multidex
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Suporte para apps com muitas bibliotecas (Firebase é pesado)
    implementation("com.android.support:multidex:1.0.3")
}
