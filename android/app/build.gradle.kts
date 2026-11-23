import com.android.build.api.artifact.SingleArtifact
import com.android.build.api.dsl.ApplicationExtension
import com.android.build.api.variant.ApplicationAndroidComponentsExtension
import com.android.build.api.variant.BuiltArtifactsLoader
import java.io.File

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

extensions.configure<ApplicationExtension> {
    namespace = "com.pamasuka.checklist_me_pamasuka"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.pamasuka.checklist_me_pamasuka"
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
        getByName("release") {
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

abstract class SalinApkChecklist : DefaultTask() {
    @get:InputDirectory
    @get:PathSensitive(PathSensitivity.RELATIVE)
    abstract val apkDirectory: DirectoryProperty

    @get:Internal
    abstract val artifactsLoader: Property<BuiltArtifactsLoader>

    @get:OutputFile
    abstract val distributionFile: RegularFileProperty

    @TaskAction
    fun salinApk() {
        val metadata = checkNotNull(artifactsLoader.get().load(apkDirectory.get())) {
            "Metadata APK rilis tidak ditemukan."
        }
        val apk = checkNotNull(metadata.elements.singleOrNull { it.filters.isEmpty() }) {
            "APK universal tidak ditemukan dalam hasil build rilis."
        }
        val target = distributionFile.get().asFile
        File(apk.outputFile).copyTo(target, overwrite = true)
        logger.lifecycle("APK untuk dibagikan: $target")
    }
}

val androidVariants = extensions.getByType<ApplicationAndroidComponentsExtension>()
androidVariants.onVariants(androidVariants.selector().withName("release")) { variant ->
    val universal = variant.outputs.singleOrNull { it.filters.isEmpty() } ?: return@onVariants
    val apkDirectoryProvider = variant.artifacts.get(SingleArtifact.APK)
    val loader = variant.artifacts.getBuiltArtifactsLoader()
    val outputPath = universal.versionName.zip(universal.versionCode) { version, build ->
        "outputs/distribusi/Checklist_ME_PAMASUKA_v${version}+${build}.apk"
    }
    val destination = layout.buildDirectory.file(outputPath)

    val copyApk = tasks.register<SalinApkChecklist>("siapkanApkChecklist") {
        description = "Menyalin APK rilis ke folder distribusi dengan nama yang memuat versi dan nomor build."
        apkDirectory.set(apkDirectoryProvider)
        artifactsLoader.set(loader)
        distributionFile.set(destination)
    }
    tasks.matching { it.name == "assembleRelease" }.configureEach {
        dependsOn(copyApk)
    }
}
