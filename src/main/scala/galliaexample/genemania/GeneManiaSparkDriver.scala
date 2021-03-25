package galliaexample.genemania

import aptus._ // for .as.noneIf
import gallia.spark._

// ===========================================================================
object GeneManiaSparkDriver {
  
  /*
   * to try local+standalone run:
   *     sbt "runMain galliaexample.genemania.GeneManiaSparkDriver /data/genemania/weights .gz 10 /tmp/genemania-spark.jsonl.gz"
   *   need to provide "lib" folder, eg with by removing "provided" and using sbt-pack     
   */
  @annotation.nowarn def main(args: Array[String]): Unit = {

    val argsItr = args.iterator      
      val inputDirPath     = argsItr.next()
      val inputCompression = argsItr.next()
      val maxFiles         = argsItr.next().toInt // 0 <=> all
      val outputDirPath    = argsItr.next()      

    // ---------------------------------------------------------------------------
    val mania = new GeneMania(
          inputDirPath, inputCompression, maxFiles.as.noneIf(_ == 0),
          outputDirPath)

    // ===========================================================================
    mania.checkpointingHook = _.rdd(_.cache)         // see t210121160956 (checkpointing task)
    mania.coalescingHook    = _.rdd(_.coalesce(128)) // a bit costly, makes it ~15% slower but better than having 1200+ output files    

    mania.outputWriter      = path => _.writeRDD(path)
    
    // ===========================================================================
    val sc: SparkContext = gallia.spark.galliaSparkContext(name = "genemania-spark")

      mania.weightInputReader  = (weightPath: String)  => sc.tsvWithHeader(weightPath )("Gene_A", "Gene_B", "Weight").convert("Weight").toDouble
      mania.networkInputReader = (networkPath: String) => sc.tsvWithHeader(networkPath)("File_Name", "Network_Group_Name", "Network_Name", "Source", "Pubmed_ID")

      mania.apply()
      
    sc.stop()
  }
  
}

// ===========================================================================