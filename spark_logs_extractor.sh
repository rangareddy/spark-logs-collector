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

echo ""

SCRIPT=`basename "$0"`

if [ $# -lt 1 ]; then
    echo "Usage: $SCRIPT <application_id>"
    exit 1
fi

APPLICATION_ID=$1
START_DATE="`date '+%Y-%m-%d %I:%M:%S'`"

echo "Extracting the Spark logs for Application <${APPLICATION_ID}> at ${START_DATE}"

CURRENT_DIR=$(pwd)
IS_EVENT_LOGS=${IS_EVENT_LOGS:-"true"}
IS_APPLICATION_LOGS=${IS_APPLICATION_LOGS:-"true"}
DESTINATION_DIR=${CURRENT_DIR}"/"${APPLICATION_ID}

#CURRENT_TIMESTAMP=${CURRENT_TIMESTAMP:-"$(date '+%Y%m%d%H%M%S')"}

APPLICATION_USER=${APPLICATION_USER:-`whoami`}

export HADOOP_USER_NAME=${APPLICATION_USER}

mkdir -p $DESTINATION_DIR

if [ $IS_APPLICATION_LOGS ]; then
   echo "Extracting the Application logs for Application <${APPLICATION_ID}>"

   #yarn application -status $APPLICATION_ID
   #if [ $status = "RUNNIN" ];then
   #     echo "Application is Running"
   #fi

   yarn logs -applicationId ${APPLICATION_ID} > ${DESTINATION_DIR}/${APPLICATION_ID}.log
   echo "Application logs extracted succefully"
   echo ""
fi

if [ $IS_EVENT_LOGS ]; then
   echo "Extracting the Event logs for Application <${APPLICATION_ID}>"

   event_log_dir=`cat /etc/spark*/conf/spark-defaults.conf | grep 'spark.eventLog.dir' | cut -d ' ' -f2 | cut -d '=' -f2`
   event_log_application_path=`hdfs dfs -ls $event_log_dir | grep ${APPLICATION_ID}`

   if [ -z "$event_log_application_path" ]; then
      echo "Applciation <${APPLICATION_ID}> is not found in event logs directory."
   else
      event_log_hdfs_path=`echo $event_log_application_path | grep -o 'hdfs.*'`
      hdfs dfs -get ${event_log_hdfs_path} ${DESTINATION_DIR}/eventLogs_${APPLICATION_ID}.log
      echo "Event logs extracted succefully"
   fi
   echo ""
fi

EXTRACTED_FILE=""

if [ ! -z "$(ls -A ${DESTINATION_DIR})" ]; then

   EXTRACTED_FILE=${APPLICATION_ID}.tgz
   tar cvfz ${EXTRACTED_FILE} ${DESTINATION_DIR} > /dev/null 2>&1
fi

if [ -d "$DESTINATION_DIR" ]; then
    rm -r -f $DESTINATION_DIR
fi

END_DATE="`date '+%Y%m%d'`"
echo "Spark Logs ${EXTRACTED_FILE} extracted successfully for Application <$APPLICATION_ID> at ${END_DATE}"
