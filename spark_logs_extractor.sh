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
    echo "Usage   : $SCRIPT <application_id>"
    echo "Example : $SCRIPT application_1234"
    exit 1
fi

APPLICATION_ID=$1
CURRENT_DIR=$(pwd)

# Destination directory for storing the event logs and application logs
DESTINATION_DIR=${CURRENT_DIR}"/"${APPLICATION_ID}

# Create the destination directory
mkdir -p $DESTINATION_DIR

# EVENT LOGS Flag
IS_EVENT_LOGS=${IS_EVENT_LOGS:-"true"}

# APPLICATION LOG Flag
IS_APPLICATION_LOGS=${IS_APPLICATION_LOGS:-"true"}

START_DATE="`date '+%Y-%m-%d %I:%M:%S'`"
echo "<${APPLICATION_ID}> - Extracting the Spark logs started at ${START_DATE}"

# If the HADOOP_USER_NAME variable value is empty then take the logged in user as HADOOP_USER_NAME
if [ -z ${HADOOP_USER_NAME} ]; then
   export HADOOP_USER_NAME=${APPLICATION_USER:-`whoami`}
fi

APPLICATION_LOG_FILE_PATH=${DESTINATION_DIR}/${APPLICATION_ID}.log
EVENT_LOG_FILE_PATH=${DESTINATION_DIR}/eventLogs_${APPLICATION_ID}.log

# If application logs is enabled then extract the application logs for application.
if [ $IS_APPLICATION_LOGS ]; then
    echo "<${APPLICATION_ID}> - Extracting the Application logs"

    yarn logs -applicationId ${APPLICATION_ID} > ${APPLICATION_LOG_FILE_PATH}
    check=$?
    if [ "$check" -eq 0 ]; then
        echo "<${APPLICATION_ID}> - Application logs extracted succefully"
    else
        echo "<${APPLICATION_ID}> - Application logs extraction failed"
        exit 0;
    fi
    echo ""
fi

# If evebt logs is enabled then extract the event logs for application.
if [ $IS_EVENT_LOGS ]; then
    echo "<${APPLICATION_ID}> - Extracting the Event logs"

    event_log_dir=`cat /etc/spark*/conf/spark-defaults.conf | grep 'spark.eventLog.dir' | cut -d ' ' -f2 | cut -d '=' -f2`
    if [ -z "$event_log_dir" ]; then
        echo "Spark Event Log directory did not found."
        exit 1
    fi
   
    event_log_application_path=`hdfs dfs -ls $event_log_dir | grep ${APPLICATION_ID}`

    if [ -z "$event_log_application_path" ]; then
        echo "<${APPLICATION_ID}> - Applciation not found in event logs <${event_log_dir}> directory."
    else
        event_log_hdfs_path=`echo $event_log_application_path | grep -o 'hdfs.*'`
        hdfs dfs -get ${event_log_hdfs_path} ${EVENT_LOG_FILE_PATH}
        check=$?
        if [ "$check" -eq 0 ]; then
            echo "<${APPLICATION_ID}> - Event logs extracted succefully"
        else
            echo "<${APPLICATION_ID}> - Event logs extraction failed"
            exit 0;
        fi
    fi
    echo ""
fi

# Compressing the extracted Spark logs using tar/zip compression

EXTRACTED_FILE=""

if [ ! -z "$(ls -A ${DESTINATION_DIR})" ]; then

    if [ -x "$(command -v tar)" ]; then
        cd $DESTINATION_DIR
        EXTRACTED_FILE=${CURRENT_DIR}/${APPLICATION_ID}.tgz
        tar cvfz ${EXTRACTED_FILE} * > /dev/null 2>&1
    elif [ -x "$(command -v zip)" ]; then
        cd $DESTINATION_DIR
        EXTRACTED_FILE=${CURRENT_DIR}/${APPLICATION_ID}.zip
        zip -q -r ${EXTRACTED_FILE} *
    else
        echo "Compression formats [tar|zip] are not installed."
    fi
fi

if [ -d "$DESTINATION_DIR" ] && [ ! -z "$EXTRACTED_FILE" ]; then
    rm -r -f $DESTINATION_DIR
fi

if [ ! -z "$EXTRACTED_FILE" ]; then
    END_DATE="`date '+%Y-%m-%d %I:%M:%S'`"
    echo "<${APPLICATION_ID}> - Spark Logs extracted successfully to <${EXTRACTED_FILE}> at ${END_DATE}"
else
    echo "<${APPLICATION_ID}> - Spark Logs extraction failed"
fi
