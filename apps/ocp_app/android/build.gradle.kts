allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Compatibility shim: some pinned plugins (e.g. isar_flutter_libs 3.1.0+1) predate
// the Android Gradle Plugin requirement that a namespace be declared in build.gradle
// instead of the manifest `package` attribute. Modern AGP fails to configure such
// modules. Derive the namespace from their manifest and raise their legacy compileSdk
// so the app builds against the Flutter-default AGP without forking the plugins.
subprojects {
    // `evaluationDependsOn(":app")` above can force some projects (notably :app) to
    // evaluate early; registering another afterEvaluate on them would throw. Skip any
    // already-evaluated project — the legacy plugins we target evaluate in normal order.
    if (state.executed) return@subprojects
    afterEvaluate {
        val android = extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        if (android != null && android.namespace == null) {
            val manifestFile = file("src/main/AndroidManifest.xml")
            val legacyPackage =
                if (manifestFile.exists()) {
                    Regex("package=\"([^\"]+)\"")
                        .find(manifestFile.readText())
                        ?.groupValues
                        ?.get(1)
                } else {
                    null
                }
            if (legacyPackage != null) {
                android.namespace = legacyPackage
                android.compileSdkVersion(36)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
