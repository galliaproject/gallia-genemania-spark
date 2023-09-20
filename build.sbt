// gallia-genemania-spark

// ===========================================================================
lazy val root = (project in file("."))
  .settings(
    organizationName     := "Gallia Project",
    organization         := "io.github.galliaproject", // *must* match groupId for sonatype
    name                 := "gallia-genemania-spark",
    version              := GalliaCommonSettings.CurrentGalliaVersion,
    homepage             := Some(url("https://github.com/galliaproject/gallia-genemania-spark")),
    scmInfo              := Some(ScmInfo(
        browseUrl  = url("https://github.com/galliaproject/gallia-genemania-spark"),
        connection =     "scm:git@github.com:galliaproject/gallia-genemania-spark.git")),
    licenses             := Seq("Apache 2" -> url("https://github.com/galliaproject/gallia-genemania-spark/blob/master/LICENSE")),
    description          := "A Scala library for data manipulation" )
  .settings(GalliaCommonSettings.mainSettings:_*)

// ===========================================================================
lazy val sparkVersion212 = "3.3.0"
lazy val sparkVersion213 = "3.3.0"

// ---------------------------------------------------------------------------
libraryDependencies ++= Seq(
  "io.github.galliaproject" %% "gallia-spark"     % GalliaCommonSettings.CurrentGalliaVersion,
  "io.github.galliaproject" %% "gallia-genemania" % GalliaCommonSettings.CurrentGalliaVersion,

  (scalaBinaryVersion.value match {
    case "2.13" => "org.apache.spark" %% "spark-core" % sparkVersion213 % "provided" withSources() withJavadoc()
    case "2.12" => "org.apache.spark" %% "spark-core" % sparkVersion212 % "provided" withSources() withJavadoc() }))

// ===========================================================================
sonatypeRepository     := "https://s01.oss.sonatype.org/service/local"
sonatypeCredentialHost :=         "s01.oss.sonatype.org"
publishMavenStyle      := true
publishTo              := sonatypePublishToBundle.value

// ===========================================================================
enablePlugins(AssemblyPlugin)

assemblyMergeStrategy in assembly := {
  case PathList("META-INF", xs @ _*) => MergeStrategy.discard
  case _                             => MergeStrategy.first }

// ===========================================================================

