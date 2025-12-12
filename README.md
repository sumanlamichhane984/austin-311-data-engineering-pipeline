\# Austin 311 Data Engineering Pipeline



This project demonstrates an end-to-end data engineering pipeline built using

Google BigQuery and Apache Airflow.



\## Overview

\- Source: Austin 311 public dataset (BigQuery public data)

\- Data trimmed to the last 2 years for efficiency

\- Stored in a custom BigQuery dataset with partitioned tables

\- Incremental updates using BigQuery MERGE

\- Orchestrated with Apache Airflow (manual DAG execution for cost control)



\## Tech Stack

\- Google BigQuery

\- Apache Airflow (Dockerized)

\- SQL

\- Python

\- Docker

\- GitHub



\## Pipeline Flow

1\. Initial load of the last 2 years of Austin 311 data

2\. Incremental merge of the last 7 days of data

3\. Manual DAG execution to avoid unnecessary cost



\## Notes

\- DAGs are triggered manually for cost control

\- No data or credentials are stored in this repository



