allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir = layout.projectDirectory.dir("../build")
layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
            android.compileSdkVersion(36)
            if (android.namespace == null) {
                android.namespace = project.group.toString()
            }
        }
    }
}

// Removed evaluationDependsOn block

tasks.register<Delete>("clean") {
    delete(layout.projectDirectory.dir("../build"))
}
