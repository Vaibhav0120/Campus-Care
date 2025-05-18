allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

gradle.beforeProject {
    if (it.path.contains("sign_in_with_apple")) {
        it.extensions.findByType(org.jetbrains.kotlin.gradle.dsl.KotlinProjectExtension::class.java)?.apply {
            jvmToolchain(11)
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Add this at the end of your file
subprojects {
    afterEvaluate {
        if (project.hasProperty('android')) {
            apply from: "${rootProject.projectDir}/kotlin-jvm-target-fix.gradle"
        }
    }
}
