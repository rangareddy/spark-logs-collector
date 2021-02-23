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

echo "<${APPLICATION_ID}> - Extracting the Spark logs started at ${START_DATE}"

CURRENT_DIR=$(pwd)
IS_EVENT_LOGS=${IS_EVENT_LOGS:-"true"}
IS_APPLICATION_LOGS=${IS_APPLICATION_LOGS:-"true"}
DESTINATION_DIR=${CURRENT_DIR}"/"${APPLICATION_ID}
APPLICATION_USER=${APPLICATION_USER:-`whoami`}

export HADOOP_USER_NAME=${APPLICATION_USER}

mkdir -p $DESTINATION_DIR

# Extract the Application logs if it enabled
if [ $IS_APPLICATION_LOGS ]; then
   echo "<${APPLICATION_ID}> - Extracting the Application logs"

   #yarn application -status $APPLICATION_ID
   #if [ $status = "RUNNIN" ];then
   #     echo "Application is Running"
   #fi

   yarn logs -applicationId ${APPLICATION_ID} > ${DESTINATION_DIR}/${APPLICATION_ID}.log
   echo "<${APPLICATION_ID}> - Application logs extracted succefully"
   echo ""
fi

# Extract the Event logs if it enabled
if [ $IS_EVENT_LOGS ]; then
   echo "<${APPLICATION_ID}> - Extracting the Event logs for Application"

   event_log_dir=`cat /etc/spark*/conf/spark-defaults.conf | grep 'spark.eventLog.dir' | cut -d ' ' -f2 | cut -d '=' -f2`
   event_log_application_path=`hdfs dfs -ls $event_log_dir | grep ${APPLICATION_ID}`

   if [ -z "$event_log_application_path" ]; then
      echo "<${APPLICATION_ID}> - Applciation not found in event logs <${event_log_dir}> directory."
   else
      event_log_hdfs_path=`echo $event_log_application_path | grep -o 'hdfs.*'`
      ls ${DESTINATION_DIR}
      hdfs dfs -get ${event_log_hdfs_path} ${DESTINATION_DIR}/eventLogs_${APPLICATION_ID}.log
      echo "<${APPLICATION_ID}> - Event logs extracted succefully"
   fi
   echo ""
fi

# Compress the spark logs
EXTRACTED_FILE=""
if [ ! -z "$(ls -A ${DESTINATION_DIR})" ]; then
   if [ -x "$(command -v tar)" ]; then
      EXTRACTED_FILE=${APPLICATION_ID}.tgz
      tar cvfz ${EXTRACTED_FILE} ${DESTINATION_DIR} > /dev/null 2>&1
   elif [ -x "$(command -v gzip)" ]; then
      EXTRACTED_FILE=${APPLICATION_ID}.gz
      gzip -c -r ${DESTINATION_DIR}/* > ${EXTRACTED_FILE}
   elif [ -x "$(command -v zip)" ]; then
      EXTRACTED_FILE=${APPLICATION_ID}.zip
      zip -q -r ${EXTRACTED_FILE} ${DESTINATION_DIR}
   else
      echo "Compression formats [tar|gzip|zip] not installed"
   fi
fi

# Deleting the destination directory
if [ -d "$DESTINATION_DIR" ] && [ ! -z "$EXTRACTED_FILE" ]; then
    rm -r -f $DESTINATION_DIR
fi

# Printing the results
if [ ! -z "$EXTRACTED_FILE" ]; then
    END_DATE="`date '+%Y-%m-%d %I:%M:%S'`"
   echo "<${APPLICATION_ID}> - Spark Logs extracted successfully to <${CURRENT_DIR}/${EXTRACTED_FILE}> at ${END_DATE}"
else
   echo "<${APPLICATION_ID}> - Spark Logs extraction failed"
fi
echo ""
