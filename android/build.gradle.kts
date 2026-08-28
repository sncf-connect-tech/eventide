group = "sncf.connect.tech.eventide"
version = "1.0-SNAPSHOT"

buildscript {
    val kotlinVersion = "2.2.20"
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:9.3.2")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("com.android.library")
    jacoco
}

extensions.configure<com.android.build.api.dsl.LibraryExtension>("android") {
    compileSdk = 36

    namespace = "sncf.connect.tech.eventide"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets {
        getByName("main").java.directories.add("src/main/kotlin")
        getByName("test").java.directories.add("src/test/kotlin")
    }

    defaultConfig {
        minSdk = flutter.minSdkVersion
    }

    testOptions {
        unitTests {
            isReturnDefaultValues = true
        }
    }

    ndkVersion = "28.2.13676358"
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

tasks.register<JacocoReport>("jacocoTestReport") {
    dependsOn("testDebugUnitTest")

    reports {
        xml.required.set(true)
        xml.outputLocation.set(file("${project.projectDir}/build/reports/jacocoTestReport.xml"))
        html.required.set(true)
        html.outputLocation.set(file("${project.projectDir}/build/reports/html"))
        csv.required.set(false)
    }

    val fileFilter = listOf(
        "**/R.class",
        "**/R$*.class",
        "**/BuildConfig.*",
        "**/Manifest*.*",
    ) // ignore pigeon generated files
    val mainSrc = "${project.projectDir}/src/main/kotlin/sncf/connect/tech/eventide/"

    sourceDirectories.setFrom(files(mainSrc))
    classDirectories.setFrom(files("${rootProject.layout.buildDirectory.get()}/${project.name}/tmp/kotlin-classes/debug/").asFileTree.matching {
        exclude(fileFilter)
    })
    executionData.setFrom(files("${rootProject.layout.buildDirectory.get()}/${project.name}/jacoco/testDebugUnitTest.exec"))
}

tasks.withType<Test> {
    configure<JacocoTaskExtension> {
        isIncludeNoLocationClasses = true
        excludes = listOf("jdk.internal.*")
    }
    useJUnitPlatform()
    finalizedBy("jacocoTestReport")

    outputs.upToDateWhen { false }

    testLogging {
        events("passed", "skipped", "failed", "standardOut", "standardError")
        showStandardStreams = true
    }
}

dependencies {
    implementation("androidx.activity:activity-ktx:1.13.0")
    implementation("androidx.fragment:fragment-ktx:1.9.0")

    testImplementation("org.jetbrains.kotlin:kotlin-test")
    testImplementation("io.mockk:mockk:1.14.11")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.11.0")
}
