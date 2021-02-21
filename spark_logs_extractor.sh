#!/bin/bash

SCRIPT=`basename "$0"`

#application_id=$1

usage() {
    echo "$SCRIPT: Usage: [application_id]"
    exit 1
}

if [ $# -lt 1 ]; then
    usage
fi

application_id=$1

current_dir=$(pwd)
event_logs=true
application_logs=true
destination_dir=${current_dir}"/"${application_id}

mkdir -p $destination_dir
ls $destination_dir

if [ $application_logs ]; then
   echo "Extracting the Application logs for applicationId ${application_id}"
   echo "yarn logs -applicationId ${application_id} > application_${application_id}.log"
   echo "Application logs extracted succefully"
   echo ""
fi

if [ $event_logs ]; then
   echo "Extracting the Event logs for Application ${application_id}"
   
   event_log_dir=`cat /etc/spark*/conf/spark-defaults.conf | grep 'spark.eventLog.dir' | cut -d ' ' -f2 | cut -d '=' -f2`
   event_log_application_path=`hdfs dfs -ls $event_log_dir | grep ${application_id}`
   
   if [ -z "$event_log_application_path" ]; then
      echo "Applciation <${application_id}> is not found in event logs directory."
   else
      event_log_hdfs_path=`echo $application_path | grep -o 'hdfs.*'`
      echo "hdfs dfs -get ${event_log_hdfs_path} > eventLogs_${application_id}.log"
      echo "Event logs extracted succefully"
   fi
   echo ""
fi

echo "Spark Logs Extracted Successfully"
