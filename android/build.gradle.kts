allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory.dir("../../build").get()

rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Novo bloco: configura o flutter_secure_storage para o SDK 37.0.
// Remover depois
subprojects {
    if (name == "flutter_secure_storage") {
        pluginManager.withPlugin("com.android.library") {
            val androidComponents = extensions.getByType(
                com.android.build.api.variant.LibraryAndroidComponentsExtension::class.java
            )

            androidComponents.finalizeDsl { androidDsl ->
                androidDsl.compileSdk {
                    version = release(37) {
                        minorApiLevel = 0
                    }
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}