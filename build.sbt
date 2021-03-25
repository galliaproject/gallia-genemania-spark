// gallia-genemania-spark

// ===========================================================================
lazy val root = (project in file("."))
  .settings(
    name         := "gallia-genemania-spark",
    version      := "0.1.0",
    scalaVersion := "2.12.13") // not 2.13.4 here, unlike core (too early for spark+2.13)
  .dependsOn(RootProject(file("../gallia-genemania")))
  .dependsOn(RootProject(file("../gallia-spark")))

// ===========================================================================
scalacOptions in Compile ++=
  Seq(
    "-encoding", "UTF-8",
    "-Ywarn-value-discard",
    "-Ywarn-unused-import")

// ===========================================================================
libraryDependencies += "org.apache.spark" %% "spark-core" % "2.4.5" % "provided" withSources() // withJavadoc(): not found https://repo1.maven.org/maven2/org/apache/spark/spark-core_2.12/2.4.5/spark-core_2.12-2.4.5-javadoc.jar

// ===========================================================================
enablePlugins(AssemblyPlugin)

assemblyMergeStrategy in assembly := {
  case PathList("META-INF", xs @ _*) => MergeStrategy.discard
  case _                             => MergeStrategy.first }

// ===========================================================================

