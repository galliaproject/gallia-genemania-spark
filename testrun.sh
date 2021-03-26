#!/bin/bash -ve
# 210315165404
#
# NOTES:
# - low-tech script to test out spark+EMR; TODO: t210325122408 - to docker?; TODO: t210325115753 - try an https://github.com/com-lihaoyi/Ammonite version of this script
# - only tested on linux (debian-based), with ca-central-1 as default region
# - make sure the cluster was terminated at the end, possibly delete the bucket as well
# - provided "AS IS", see LICENSE file for details

# ===========================================================================
# init
hash jq  # tested with 1.6
hash sbt # tested with 1.4.7
hash aws # tested with 1.18.69 (aws-cli)
hash git # tested with 2.25.1

# ---------------------------------------------------------------------------
# must be setup with aws-cli already, see https://docs.aws.amazon.com/credref/latest/refdocs/file-location.html
ls \
  ~/.aws/config \
  ~/.aws/credentials

# ---------------------------------------------------------------------------
MAX_FILES=$1 # "ALL" or a number; use eg 1000 for all (there are ~650 in total)
  WORKERS=$2 # if processing all ~650 files, then 60 is a good number

MAX_FILES=${MAX_FILES:=10}
  WORKERS=${WORKERS:=4}

if [ "${MAX_FILES}" == "ALL" ]; then MAX_FILES=1000; fi

# ---------------------------------------------------------------------------
     NAME="gallia-genemania-spark"
   BUCKET="${NAME?}$(date '+%y%m%d%H%M%S')"
  VERSION="0.1.0"
echo ${BUCKET?}

# ---------------------------------------------------------------------------
 CORE_COMMIT="e82e390"
SPARK_COMMIT="5f848a8"
MANIA_COMMIT="ff6634c"
      COMMIT="bbedb51"

# ---------------------------------------------------------------------------
mkdir /tmp/${BUCKET?}

# ===========================================================================
# code

mkdir /tmp/${BUCKET?}/code

# ---------------------------------------------------------------------------
## get code
cd /tmp/${BUCKET?}/code

git clone https://github.com/galliaproject/gallia-core     ; cd ./gallia-core     ; git checkout ${CORE_COMMIT?} ; cd ..
git clone https://github.com/galliaproject/gallia-spark    ; cd ./gallia-spark    ; git checkout ${SPARK_COMMIT?}; cd ..
git clone https://github.com/galliaproject/gallia-genemania; cd ./gallia-genemania; git checkout ${MANIA_COMMIT?}; cd ..
git clone https://github.com/galliaproject/${NAME?}        ; cd ./${NAME?}        ; git checkout ${COMMIT?}      ; cd ..

# ---------------------------------------------------------------------------
# disable 2.13
cat  /tmp/${BUCKET?}/code/gallia-core/project/GalliaScalaVersions.scala | sed 's/scala213,/\/\/scala213,/' > /tmp/${BUCKET?}/code/gallia-core/project/GalliaScalaVersions.scala.tmp &&
  mv /tmp/${BUCKET?}/code/gallia-core/project/GalliaScalaVersions.scala.tmp                                  /tmp/${BUCKET?}/code/gallia-core/project/GalliaScalaVersions.scala # see t210309100048

# ---------------------------------------------------------------------------
## create uberjar (minus spark itself, provided by EMR)
cd /tmp/${BUCKET?}/code/${NAME?} && sbt assembly # see project/plugins.sbt
ls /tmp/${BUCKET?}/code/${NAME?}/target/scala-2.12/${NAME?}-assembly-${VERSION?}.jar # created by assembly command above

# ---------------------------------------------------------------------------
# backup source for good measure
cd /tmp/${BUCKET?}; tar -zcf code.tgz ./code
ls /tmp/${BUCKET?}/code.tgz
du -sh /tmp/${BUCKET?}/code.tgz


# ===========================================================================
# input data

mkdir /tmp/${BUCKET?}/data
cd    /tmp/${BUCKET?}/data

# ---------------------------------------------------------------------------
## gather input data locally
if true; then

  # 643 files at time of writing, so about ~1h with the pauses
  PARENT="http://genemania.org/data/current/Homo_sapiens"

  curl -sS http://genemania.org/data/current/Homo_sapiens/networks.txt | gzip -c > /tmp/${BUCKET?}/data/networks.txt.gz
  for FILENAME in $(zcat /tmp/${BUCKET?}/data/networks.txt.gz | tail -n+2 | cut -f1 | head -n ${MAX_FILES?}); do
    sleep 5 # let's be considerate
    echo -e "\t${FILENAME?}"

    # note: GZIP is not best format here but will do for demonstration purposes
    curl -sS http://genemania.org/data/current/Homo_sapiens/${FILENAME?} | gzip -c > /tmp/${BUCKET?}/data/${FILENAME?}.gz
  done
  
else  # if want to skip and use a local copy instead (recommended if doing more than one run)
  : # cp <your-local-copy>/* /tmp/${BUCKET?}/data  
fi


# ===========================================================================
## create and provision s3 bucket

aws s3api \
  create-bucket \
    --create-bucket-configuration LocationConstraint=$(aws configure get region) \
    --bucket ${BUCKET?} # see https://github.com/aws/aws-cli/issues/2603

# ---------------------------------------------------------------------------
aws s3 cp /tmp/${BUCKET?}/code.tgz                                                          s3://${BUCKET?}/source.tgz
aws s3 cp /tmp/${BUCKET?}/code/${NAME?}/target/scala-2.12/${NAME?}-assembly-${VERSION?}.jar s3://${BUCKET?}/
aws s3 cp /tmp/${BUCKET?}/data                                                              s3://${BUCKET?}/input --recursive # ~5min (TODO: TBC)


# ===========================================================================
# EMR cluster creation+run

# ---------------------------------------------------------------------------
# create cluster with step to execute code
CLUSTER=$(\
  aws emr create-cluster \
    --release-label     emr-6.2.0    \
    --applications      Name=Spark   \
    --use-default-roles              \
    \
    --name              ${NAME?}     \
    --instance-type     m4.large     \
    --instance-count    $[WORKERS+1] \
    --log-uri           s3://${BUCKET?}/logs/ \
    --auto-terminate --steps '{
      "Type"           : "Spark",
      "ActionOnFailure": "TERMINATE_CLUSTER",
      "Name"           : "'${NAME?}'",
      "Args"           : [
          "--class", "galliaexample.genemania.GeneManiaSparkDriver",
            "s3://'${BUCKET?}'/'${NAME?}'-assembly-'${VERSION?}'.jar",
              "s3://'${BUCKET?}'/input", ".gz", "'${MAX_FILES?}'",
              "s3://'${BUCKET?}'/output" ] }') # "0" for "all"

# ---------------------------------------------------------------------------
## grab cluster ID (eg "j-2PTGMQSRS7GHG")
CLUSTER_ID=$(echo ${CLUSTER?} | jq -r '.ClusterId')
echo "CLUSTER_ID=${CLUSTER_ID?}"
echo ${CLUSTER?} | jq -c

# ---------------------------------------------------------------------------
## poll cluster until completion (it takes ~7 minutes just to create the cluster)
sleep 5
while true; do
  STATE=$(aws emr describe-cluster --cluster-id ${CLUSTER_ID?} | jq -r '.Cluster.Status.State')
  echo -e "\t${STATE?}"

  # valid states: STARTING, BOOTSTRAPPING, RUNNING, WAITING, TERMINATING, TERMINATED, and TERMINATED_WITH_ERRORS.
  if [[ "${STATE?}" =~ ^TERMINATED ]]; then break; fi
  sleep 30
done

# ===========================================================================
# show results

# ---------------------------------------------------------------------------
echo "aws s3 ls s3://${BUCKET?}/output/"
aws s3 ls s3://${BUCKET?}/output/ | wc -l
aws s3 ls s3://${BUCKET?}/output/ | grep "part-" | head # should show some output files if did not terminate with errors

# ---------------------------------------------------------------------------
## grab step ID (eg "s-15GAUY1B34G0W")
STEP_ID=$(aws emr list-steps --cluster-id ${CLUSTER_ID?} | jq -r '.Steps[].Id')
echo "STEP_ID=${STEP_ID?}" && echo

echo && echo
echo && echo "aws s3 ls s3://${BUCKET?}/logs/${CLUSTER_ID?}/steps/${STEP_ID?}/"
echo && echo "aws s3 cp s3://${BUCKET?}/logs/${CLUSTER_ID?}/steps/${STEP_ID?}/stderr.gz ."
echo && echo "aws s3 cp s3://${BUCKET?}/logs/${CLUSTER_ID?}/steps/${STEP_ID?}/stdout.gz ."
echo && echo "aws s3 cp s3://${BUCKET?}/logs/${CLUSTER_ID?}/steps/${STEP_ID?}/controller.gz ."
echo && echo
echo && echo "aws emr describe-cluster --cluster-id ${CLUSTER_ID?}"
echo && echo "aws emr describe-step    --cluster-id ${CLUSTER_ID?} --step-id ${STEP_ID?}"
echo && aws emr describe-cluster --cluster-id ${CLUSTER_ID?} | jq '.Cluster.Status.State' # make sure TERMINATED

# ---------------------------------------------------------------------------
read -p "make sure the cluster is terminated, and consider deleting the bucket '${BUCKET?}'; OK?"

# ===========================================================================

