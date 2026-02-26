plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // ✅ Google Services لازم يكون مفعّل هنا (module level)
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.medical_booking"

    // استخدم قيم Flutter الافتراضية
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.medical_booking"

        // 🔴 مهم: minSdk ≥ 21
        minSdk = maxOf(21, flutter.minSdkVersion)

        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ✅ Java/Kotlin + تفعيل الـ desugaring
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    buildTypes {
        release {
            // مؤقتاً توقيع debug حتى يعمل build --release (بدّل لاحقًا بتوقيعك)
            signingConfig = signingConfigs.getByName("debug")
            // يمكنك تفعيل minify/proguard لاحقًا
            // isMinifyEnabled = true
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        debug {
            // إعدادات debug (اختياري)
        }
    }

    // (اختياري) لو صادفت تعارضات META-INF مع بعض تبعيات Firebase/Okio/OkHttp
    // packaging {
    //     resources {
    //         excludes += setOf(
    //             "META-INF/DEPENDENCIES",
    //             "META-INF/NOTICE",
    //             "META-INF/LICENSE",
    //             "META-INF/LICENSE.txt",
    //             "META-INF/NOTICE.txt",
    //             "META-INF/*"
    //         )
    //     }
    // }
}

flutter {
    source = "../.."
}

dependencies {
    // 🔵 desugaring مطلوبة مع isCoreLibraryDesugaringEnabled
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // ✅ منصة Firebase BoM — تثبّت نسخ متوافقة تلقائياً لكل SDKs
    implementation(platform("com.google.firebase:firebase-bom:33.6.0"))

    // 🔔 Firebase Cloud Messaging
    implementation("com.google.firebase:firebase-messaging")

    // 🔥 Cloud Firestore (للاختبارات والبيانات)
    implementation("com.google.firebase:firebase-firestore")

    // (اختياري) Analytics لو حاب
    // implementation("com.google.firebase:firebase-analytics")

    // (اختياري) Auth لو ستفعل تسجيل الدخول عبر Firebase
    // implementation("com.google.firebase:firebase-auth")
}