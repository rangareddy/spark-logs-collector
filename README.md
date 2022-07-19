# Spark Logs Collector - Collect Application and Event logs

<p align="center">
  <img src="https://github.com/rangareddy/spark-logs-collector/blob/main/spark_logs_extractor_logo.png?raw=true">
</p>

## What is the Spark Logs Collector? 

Spark Logs Collector is a simple utility tool used for collecting YARN Application logs and Event logs. The collected log data is used to troubleshoot the [Spark](https://spark.apache.org/) applications.

## Advantages

The following are the advantages of **Spark Logs Collector**

1. We can collect both **Application logs** and **Event logs**.
1. Collected logs are in **compressed (`[tar|zip]`)** format.
1. No need to run any commands to collect the logs.
1. We can collect the logs even in a **Kerberized cluster**.

## How to use

**Step1:** Download the **spark_logs_collector.sh** script to any location (for example /tmp) and give the **execute** permission.

```sh
wget https://raw.githubusercontent.com/rangareddy/spark-logs-collector/main/spark_logs_collector.sh
chmod +x spark_logs_collector.sh
```

**Step2:** While running the **spark_logs_collector.sh** script, you need to provide the `application_id`.

```sh
sh spark_logs_collector.sh <application_id>
```

> Replace **application_id** with your **spark application id**.

**Example:**

```sh
sh spark_logs_collector.sh application_1658141526730_0004
```

## Additional Info

By default, this utility will collect both application and event logs. If you don't want to collect any one of the logs you can disable it.

**Disabling the Event logs:**

```sh
export EVENT_LOGS_ENABLED=fase
```

**Disabling the Application logs:**

```sh
export APPLICATION_LOGS_ENABLED=fase
```

Even you can change the different user, to collect the Spark logs.

```sh
export APPLICATION_USER=rangareddy
```

## Troubleshooting

**Issue:** `Permission denied: user=<USER_NAME>, access=READ, inode="<DIRECTORY_PATH>":exam:spark:-rwxrwx`

**Description:** User <USER_NAME> don't have hdfs permission to access the <DIRECTORY_PATH> directory.

**Solution:**

1. Provide the correct permission to the user to access the directory. 
2. Run the script who has permisson to access the directory.

**Issue:** `Failed on local exception: java.io.IOException: org.apache.hadoop.security.AccessControlException: Client cannot authenticate via:[TOKEN, KERBEROS]`

**Description:** You don't have proper kerberos ticket or kerberos ticket got expired. 

**Solution:**

1. Run with `kinit <principal name> [<password>]`

## Issue Tracking

Any suggestions or questions, please [create an issue](https://github.com/rangareddy/spark-logs-collector/issues/new) to feedback.

## Contributing

Do you want to contribute to this project, please connect with me on [Linkedin](https://www.linkedin.com/in/ranga-reddy-big-data-developer/).

## License

Copyright ©2022 Ranga Reddy, https://github.com/rangareddy

* **Twitter:** https://twitter.com/avula_ranga
* **LinkedIn:** https://www.linkedin.com/in/ranga-reddy-big-data-developer/
