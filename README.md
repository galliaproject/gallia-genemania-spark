<p align="center"><img src="./images/logo.png" alt="icon"></p>

See original announcements on:

- Spark [mailing list](http://todo)
- GeneMania [google group](https://groups.google.com/g/genemania-discuss)
- [BioStars](https://www.biostars.org/p/490469/)

For more information, see gallia-core [documentation](https://github.com/galliaproject/gallia-core/blob/init/README.md#introducing-gallia-a-scala-library-for-data-manipulation), in particular:
- The [Spark](https://github.com/galliaproject/gallia-core/blob/master/README.md#spark) section
- The [examples](https://github.com/galliaproject/gallia-core/blob/master/README.md#examples) section

### Description

This is the [Spark RDD-powered](http://todo) counterpart to the [genemania parent repo](https://github.com/galliaproject/gallia-genemania) (which was using Gallia's ["poor man scaling"](https://github.com/galliaproject/gallia-core/blob/init/README.md#poor-man-scaling) instead of Spark)

#### Test Run

You can test it by running the [./testrun.sh](https://github.com/galliaproject/gallia-genemania-spark/blob/master/testrun.sh) script at the root of the repo, provided you are set up with `aws-cli` and don't mind the cost (see below).

The script does the following:
- Creates an S3 bucket for the code and data
- Retrieves code and uploads it to the bucket (source+binaries)
- Retrieves the data (or a subset thereof) and uploads it to the bucket
- Creates an EMR Spark cluster and run the program as a single step
- Awaits until termination and logs results

To run it on a small subset (expect ~$3<sup>[[2]](#cost-estimate)</sup> in AWS charges), use:

```bash
./testrun.sh 10 4 # process first 10 files, using 4 workers
```

To run it in full (expect ~$18<sup>[[2]](#cost-estimate)</sup> in AWS charges), use:

```bash
./testrun.sh ALL <number-of-workers> # eg 60 workers
```

The full EMR run will take about 120 minutes with 60 workers<sup>[[1]](#number-of-workers)</sup>. As one would expect, it follows the distribution below:

![|distribution](https://lh6.googleusercontent.com/XbzNZr05dSnANpS3xfp9Vh-BbWcXUDrpPRXUJNLdMckwGSx99J_PaD4THImK5YQlwmCT7iFn69fHgMB_VZ07kmF_uWXADBIBUyGZjxqYOOFHW1DagsJEFbeFDCMc-ayHl5JRKyxf)

### Input

Same input as [parent repo](http://todo), except uploaded to an s3 bucket first: `s3://<bucket>/input/`

### Output

Same output as [parent repo](http://todo), except made available on s3 bucket as `s3://<bucket>/output/part-NNNNN.gz` files

### Limitations

Notable limitations are:

- Only available for Scala 2.12 because:
  - [sbt-assembly](https://github.com/sbt/sbt-assembly) does not seem to be available for 2.13
  - Spark support for 2.13 is still immature
- The I/O abstractions need to be aligned with the core's, they are somewhat hacky at the moment:
  - gallia-core's `io.in` mechanisms ([fluency](https://github.com/galliaproject/gallia-core/blob/init/src/main/scala/gallia/io/in/ReadFluency.scala), [actions](https://github.com/galliaproject/gallia-core/tree/init/src/main/scala/gallia/actions/in) and [atoms](https://github.com/galliaproject/gallia-core/blob/master/src/main/scala/gallia/atoms/AtomsIX.scala)) vs [gallia-spark](https://github.com/galliaproject/gallia-spark/blob/master/src/main/scala/gallia/spark/SparkPackage.scala#L40)'s
  - gallia-core's `io.out` mechanisms ([fluency](https://github.com/galliaproject/gallia-core/blob/init/src/main/scala/gallia/io/out/WriteFluency.scala), [actions](https://github.com/galliaproject/gallia-core/blob/master/src/main/scala/gallia/actions/out/ActionsOut.scala) and [atoms](https://github.com/galliaproject/gallia-core/blob/master/src/main/scala/gallia/atoms/AtomsXO.scala)) vs [gallia-spark](https://github.com/galliaproject/gallia-spark/blob/master/src/main/scala/gallia/spark/SparkPackage.scala#L76)'s

See list of [spark-related tasks](https://github.com/galliaproject/gallia-docs/blob/master/tasks.md#spark) for more limitations.

#### Footnotes

- <sup>[1]</sup> <a name="number-of-workers"></a> ~+1h to accumulate the input data and upload it on s3 bucket (using a 5 seconds courtesy delay in between each request)
- <sup>[2]</sup> <a name="cost-estimate"></a>Cost estimates provided are not guaranteed __at all__, run it at own risk (but please let me know if yours are significantly different)

## Contact
You may contact the author at cros.anthony@gmail.com

