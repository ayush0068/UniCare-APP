import com.android.build.gradle.BaseExtension

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

// Some plugins (flutter_webrtc included) still declare an old
// compileSdkVersion (e.g. 31) in their own module's build.gradle,
// independently of the app's own compileSdk setting above. That
// mismatch fails AAR metadata checks against newer androidx libraries.
// Forcing every subproject (app + every plugin) onto the same,
// current SDK here fixes it without touching each plugin individually
// and without needing to fork/patch any plugin.
//
// IMPORTANT: this must be registered BEFORE the evaluationDependsOn(":app")
// block below — that call eagerly evaluates the ":app" project right then,
// and afterEvaluate can't be attached to a project that's already evaluated.
subprojects {
    afterEvaluate {
        extensions.findByType(BaseExtension::class.java)?.let { android ->
            android.compileSdkVersion(36)
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}