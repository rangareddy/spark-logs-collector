#!/bin/bash

#application_id=$1
application_id="application_1234"

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
   
   echo "Extracting the Event logs for applicationId ${application_id}"
   event_log_dir="/user/spark/applicationHistory/${application_id}"
   echo "hdfs dfs -get $event_log_dir > eventLogs_${application_id}.log"
   echo "Event logs extracted succefully"
   echo ""
fi

echo "Spark Logs Extracted Successfully"
