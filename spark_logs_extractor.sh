#!/bin/bash

###########################################################################################################
#    _____                  _      _                       ______      _                  _               #
#   / ____|                | |    | |                     |  ____|    | |                | |              #
#  | (___  _ __   __ _ _ __| | __ | |     ___   __ _ ___  | |__  __  _| |_ _ __ __ _  ___| |_ ___  _ __   #
#   \___ \| '_ \ / _` | '__| |/ / | |    / _ \ / _` / __| |  __| \ \/ / __| '__/ _` |/ __| __/ _ \| '__|  #
#  _ ___) | |_) | (_| | |  |   <  | |___| (_) | (_| \__ \ | |____ >  <| |_| | | (_| | (__| || (_) | |     #
#  |_____/| .__/ \__,_|_|  |_|\_\ |______\___/ \__, |___/ |______/_/\_\\__|_|  \__,_|\___|\__\___/|_|     #
#         | |                                   __/ |                                                     #
#         |_|                                  |___/                                                      #
#                                                                                                         #
#  Usage   : spark_logs_extractor.sh <application_id>                                                     #
#  Author  : Ranga Reddy                                                                                  #
#  Version : v1.0                                                                                         #
#  Date    : 22-Feb-2021                                                                                  #
###########################################################################################################

SCRIPT=`basename "$0"`
usage() {
    echo "Usage: $SCRIPT <application_id>"
    exit 1
}

if [ $# -lt 1 ]; then
    usage
fi

CURRENT_DATE="`date '+%Y%m%d'`"
CURRENT_TIMESTAMP=${CURRENT_TIMESTAMP:-"$(date '+%Y%m%d%H%M%S')"}
APPLICATION_USER=${APPLICATION_USER:-`whoami`}

APPLICATION_ID=$1

current_dir=$(pwd)
event_logs=true
application_logs=true
destination_dir=${current_dir}"/"${APPLICATION_ID}

mkdir -p $destination_dir
ls $destination_dir

if [ $application_logs ]; then
   echo "Extracting the Application logs for applicationId ${APPLICATION_ID}"
   yarn application -status $ApplicationId
   if [ $status = “RUNNING” ];then
        echo "Application is Running"    
   fi

   echo "yarn logs -applicationId ${APPLICATION_ID} > application_${APPLICATION_ID}.log"
   echo "Application logs extracted succefully"
   echo ""
fi

if [ $event_logs ]; then
   echo "Extracting the Event logs for Application <${APPLICATION_ID}>"
   
   event_log_dir=`cat /etc/spark*/conf/spark-defaults.conf | grep 'spark.eventLog.dir' | cut -d ' ' -f2 | cut -d '=' -f2`
   event_log_application_path=`hdfs dfs -ls $event_log_dir | grep ${APPLICATION_ID}`
   
   if [ -z "$event_log_application_path" ]; then
      echo "Applciation <${APPLICATION_ID}> is not found in event logs directory."
   else
      event_log_hdfs_path=`echo $application_path | grep -o 'hdfs.*'`
      echo "hdfs dfs -get ${event_log_hdfs_path} > eventLogs_${APPLICATION_ID}.log"
      echo "Event logs extracted succefully"
   fi
   echo ""
fi

echo "Spark Logs Extracted successfully for Application <$APPLICATION_ID>"
