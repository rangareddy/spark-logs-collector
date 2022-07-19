#!/bin/bash

###########################################################################################################
#   _____                  _      _                        _____      _ _           _                     #
#  / ____|                | |    | |                      / ____|    | | |         | |                    #
# | (___  _ __   __ _ _ __| | __ | |     ___   __ _ ___  | |     ___ | | | ___  ___| |_ ___  _ __         #
#  \___ \| '_ \ / _` | '__| |/ / | |    / _ \ / _` / __| | |    / _ \| | |/ _ \/ __| __/ _ \| '__|        # 
#  ____) | |_) | (_| | |  |   <  | |___| (_) | (_| \__ \ | |___| (_) | | |  __/ (__| || (_) | |           #
# |_____/| .__/ \__,_|_|  |_|\_\ |______\___/ \__, |___/  \_____\___/|_|_|\___|\___|\__\___/|_|           # 
#        | |                                   __/ |                                                      #
#        |_|                                  |___/                                                       #
#                                                                                                         #
#  Usage   : spark_logs_collector.sh <application_id>                                                     #
#  Author  : Ranga Reddy                                                                                  #
#  Version : v1.0                                                                                         #
#  Date    : 19-Jul-2022                                                                                  #
#                                                                                                         #
###########################################################################################################

set -e -o pipefail

SCRIPT=$(basename "$0")

usage() {
    echo ""
    echo "Usage   : sh $SCRIPT <application_id>"
    echo "Example : sh $SCRIPT application_1658141526730_0004"
    echo ""
    exit 1;
}

if [ $# -lt 1 ]; then
    usage
fi

APPLICATION_ID=$1
EVENT_LOGS_ENABLED=${EVENT_LOGS_ENABLED:-"true"}
APPLICATION_LOGS_ENABLED=${APPLICATION_LOGS_ENABLED:-"true"}
CURRENT_DIR=$(pwd)

log_info() {
    INFO_MSG="$1"
    CURR_DATE="$(date '+%Y-%m-%d %I:%M:%S')"
    echo "$APPLICATION_ID - $CURR_DATE INFO : ${INFO_MSG}" 1>&2
}

log_error() {
    ERROR_MSG="$1"
    CURR_DATE="$(date '+%Y-%m-%d %I:%M:%S')"
    echo "$APPLICATION_ID - $CURR_DATE ERROR : ${ERROR_MSG}" 1>&2
}

# Collecting the Spark Application logs if it is enabled
collect_spark_application_logs() {
    TARGET_DIR=$1
    APPLICATION_LOG_FILE_PATH=${TARGET_DIR}/${APPLICATION_ID}.log
    log_info "Collecting the Application logs"

    yarn logs -applicationId "${APPLICATION_ID}" > "${APPLICATION_LOG_FILE_PATH}" 2>&1 
    application_log_collect_status=$?
    if [ "$application_log_collect_status" -eq 0 ]; then
        log_info "Application logs collected succefully."
    else
        log_error "Application logs collect failed."
        exit 1;
    fi
}

# Collecting the Spark Event logs if it is enabled
collect_spark_event_logs() {
    TARGET_DIR=$1
    EVENT_LOG_FILE_PATH=${TARGET_DIR}/eventLogs_${APPLICATION_ID}.log
    log_info "Collecting the Event logs"

    if [ ! -f /etc/spark/conf/spark-defaults.conf ]; then
        log_error "spark-defaults.conf file does not present in /etc/spark/conf directory."
        exit 1;
    fi

    EVENT_LOG_DIR=$(cat /etc/spark*/conf/spark-defaults.conf | grep 'spark.eventLog.dir' | grep -v '#' | cut -d ' ' -f2 | cut -d '=' -f2)
    if [ -z "$EVENT_LOG_DIR" ]; then
        log_error "Spark Event log directory did not found."
        exit 1;
    fi

    for EVENT_LOG_HDFS_PATH in $(hdfs dfs -ls $EVENT_LOG_DIR | awk '{print $NF}' | grep ${APPLICATION_ID} | tr '\n' ' ')
    do
        hdfs dfs -get "${EVENT_LOG_HDFS_PATH}" "${TARGET_DIR}"
        event_log_collect_status=$?
        if [ "$event_log_collect_status" -eq 0 ]; then
            EVENT_FILE_NAME="${EVENT_LOG_HDFS_PATH##*/}"
            log_info "Event log <${EVENT_FILE_NAME}> file collected succefully."
        else
            log_error "Event logs extraction failed."
            exit 1;
        fi
    done
}

# Compress the collected Spark logs using tar/zip compression
compress_spark_logs() {
    
    DESTINATION_DIR=$1
    EXTRACTED_FILE=""

    if [ -n "$(ls -A "${DESTINATION_DIR}")" ]; then
        cd "$DESTINATION_DIR"
        if [ -x "$(command -v tar)" ]; then # If tar command is available then collect the logs tgz format
            EXTRACTED_FILE=${CURRENT_DIR}/${APPLICATION_ID}.tgz
            tar cvfz "${EXTRACTED_FILE}" * > /dev/null 2>&1
        elif [ -x "$(command -v zip)" ]; then # If zip command is available then collect the logs zip format
            EXTRACTED_FILE=${CURRENT_DIR}/${APPLICATION_ID}.zip
            zip -q -r "${EXTRACTED_FILE}" *
        else
            log_error "Compression formats [tar|zip] are not installed."
        fi
    fi

    if [ -d "$DESTINATION_DIR" ] && [ -n "$EXTRACTED_FILE" ]; then
        rm -r -f "$DESTINATION_DIR"
    fi

    if [ -n "$EXTRACTED_FILE" ]; then
        log_info "Spark Logs extracted successfully to <${EXTRACTED_FILE}>."
    else
        log_error "Spark Logs extraction failed."
    fi
}

main() {

    if [ "$EVENT_LOGS_ENABLED" = true ] || [ "$APPLICATION_LOGS_ENABLED" = true ]; then
        
        # If the HADOOP_USER_NAME variable value is empty then take the logged in user as HADOOP_USER_NAME
        if [ -z "${HADOOP_USER_NAME}" ]; then
            export HADOOP_USER_NAME=${APPLICATION_USER:-$(whoami)}
        fi

        # Destination directory for storing the event logs and application logs
        DESTINATION_DIR=${CURRENT_DIR}"/"${APPLICATION_ID}
        mkdir -p "$DESTINATION_DIR"

        log_info "Collecting the Spark logs using <$HADOOP_USER_NAME> user."

        if [ "$EVENT_LOGS_ENABLED" = true ]; then
            collect_spark_event_logs "$DESTINATION_DIR"
        fi
        if [ "$APPLICATION_LOGS_ENABLED" = true ]; then
            collect_spark_application_logs "$DESTINATION_DIR"
        fi
        compress_spark_logs "$DESTINATION_DIR"
    else 
        log_error "Both Application logs and Event logs are not enabled."
    fi
}

main