// gallia-genemania-spark

// ===========================================================================
lazy val root = (project in file("."))
  .settings(
    organizationName     := "Gallia Project",
    organization         := "io.github.galliaproject", // *must* match groupId for sonatype
    name                 := "gallia-genemania-spark",
    version              := "0.3.0",    
    homepage             := Some(url("https://github.com/galliaproject/gallia-genemania-spark")),
    scmInfo              := Some(ScmInfo(
        browseUrl  = url("https://github.com/galliaproject/gallia-genemania-spark"),
        connection =     "scm:git@github.com:galliaproject/gallia-genemania-spark.git")),
    licenses             := Seq("BSL 1.1" -> url("https://github.com/galliaproject/gallia-genemania-spark/blob/master/LICENSE")),
    description          := "A Scala library for data manipulation" )
  .settings(GalliaCommonSettings.mainSettings:_*)
  .settings(scalaVersion := "2.12.13") // override core's (too early for spark+2.13)

// ===========================================================================    
lazy val galliaVersion = "0.3.0"

// ---------------------------------------------------------------------------
libraryDependencies ++= Seq(
  "io.github.galliaproject" %% "gallia-spark"     % galliaVersion,
  "io.github.galliaproject" %% "gallia-genemania" % galliaVersion,
  "org.apache.spark"        %% "spark-core" % "2.4.5" % "provided" withSources()) // withJavadoc(): not found https://repo1.maven.org/maven2/org/apache/spark/spark-core_2.12/2.4.5/spark-core_2.12-2.4.5-javadoc.jar

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

