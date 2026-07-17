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

// Bazı eski eklentiler (ör. receive_sharing_intent) Java'yı 11, Kotlin'i 17
// hedefliyor; yeni Gradle bunu tutarsız bulup derlemeyi durduruyor. Alt
// modüllerin Java derlemesini de 17'ye çekince ikisi eşitlenir (Kotlin
// zaten 17). Kotlin tipini referanslamamak için yalnızca Java tarafı
// ayarlanır — kök derleme sınıf yolu sade kalır.
subprojects {
    tasks.withType<org.gradle.api.tasks.compile.JavaCompile>().configureEach {
        sourceCompatibility = JavaVersion.VERSION_17.toString()
        targetCompatibility = JavaVersion.VERSION_17.toString()
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
