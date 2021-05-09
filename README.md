# Spark Logs Extractor

<p align="center">
  <img src="https://github.com/rangareddy/spark-logs-extractor/blob/main/spark_logs_extractor_logo.png">
</p>

By using this tool, we can collect the **Spark** **Application** and **Event Logs** with **compressed([tar|zip])** format. As of now by using this tool, we can collect the Spark logs in **HDP, CDH** and **CDP** clusters only.

The following are steps to use this tool:

**Step1:** Download the **spark_logs_extractor.sh** script to any temp location and give the **execute** permission.
```sh
cd /tmp
wget https://raw.githubusercontent.com/rangareddy/spark-logs-extractor/main/spark_logs_extractor.sh
chmod +x  spark_logs_extractor.sh
```
**Step2:** While Runing the **spark_logs_extractor.sh** script, provide the application_id.
```sh
sh spark_logs_extractor.sh <application_id>
```
> Replace **application_id** with your **spark application id**.
