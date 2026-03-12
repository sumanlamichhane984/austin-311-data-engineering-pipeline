# Austin 311 Data Engineering Pipeline

![GCP](https://img.shields.io/badge/Google_Cloud-4285F4?style=for-the-badge&logo=google-cloud&logoColor=white)
![BigQuery](https://img.shields.io/badge/BigQuery-4285F4?style=for-the-badge&logo=google-cloud&logoColor=white)
![Airflow](https://img.shields.io/badge/Apache_Airflow-017CEE?style=for-the-badge&logo=apache-airflow&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)

---

## Overview

This project implements an incremental data engineering pipeline that ingests Austin 311 service request data from the BigQuery public dataset into a custom partitioned BigQuery table. The pipeline uses a SQL MERGE operation orchestrated by Apache Airflow (running locally via Docker) to perform daily incremental updates — loading only the last 7 days of data on each run.

The pipeline is designed for cost-conscious engineering: manual DAG execution avoids unnecessary BigQuery query costs while still demonstrating production-grade incremental load patterns.

---

## Architecture

```
BigQuery Public Dataset
bigquery-public-data.austin_311.311_service_requests
        |
        v
SQL MERGE Operation (Incremental - Last 7 Days)
  - Filters records: DATE(created_date) >= CURRENT_DATE - 7
  - WHEN MATCHED → UPDATE existing records
  - WHEN NOT MATCHED → INSERT new records
  - Deduplication key: unique_key
        |
        v
Custom BigQuery Table
jenish-my-first-dog.austin_data_sets.raw_austin_311
  - 13 columns, strongly typed
  - Partitioned by created_date
  - Incremental history maintained
        |
        v
Apache Airflow (Docker)
  - DAG: austin_311_merge_manual
  - Schedule: Manual trigger only
  - Executor: LocalExecutor
  - SQL loaded via template_searchpath
```

---

## Tech Stack

| Tool | Purpose |
|---|---|
| BigQuery Public Data | Source: Austin 311 service requests |
| BigQuery | Destination analytics warehouse |
| SQL MERGE | Incremental upsert logic |
| Apache Airflow 2.9.3 | Pipeline orchestration |
| Docker + Docker Compose | Local Airflow environment |
| Python 3 | DAG definition |
| PostgreSQL 15 | Airflow metadata database |

---

## Repository Structure

```
austin-311-data-engineering-pipeline/
├── Dags/
│   └── austin_311_merge_manual.py     # Airflow DAG definition
├── sql/
│   └── merge_austin_311_last_7_days.sql  # BigQuery MERGE SQL
├── docker-compose.yml                 # Local Airflow setup (4 services)
├── README.md
└── .gitignore
```

---

## Data Model

### Source Table
`bigquery-public-data.austin_311.311_service_requests` — Austin's public 311 service request dataset updated regularly by the City of Austin.

### Destination Table
`austin_data_sets.raw_austin_311`

| Column | Type | Description |
|---|---|---|
| unique_key | STRING | Primary key — deduplication identifier |
| complaint_description | STRING | Description of the 311 complaint |
| source | STRING | How the request was submitted |
| status | STRING | Current status of the request |
| status_change_date | DATE | When the status last changed |
| created_date | DATE | When the request was created |
| last_update_date | DATE | When the record was last updated |
| close_date | DATE | When the request was closed |
| incident_address | STRING | Full address of the incident |
| street_number | STRING | Street number |
| street_name | STRING | Street name |
| city | STRING | City |
| incident_zip | STRING | ZIP code |

---

## MERGE Logic — How Incremental Load Works

The core of this pipeline is a BigQuery MERGE statement that runs daily:

```
Source: Last 7 days from public dataset
    |
    ├── unique_key EXISTS in destination → UPDATE all fields
    └── unique_key NOT in destination  → INSERT new record
```

**Why 7 days instead of 1 day?**
Austin 311 records are frequently updated after creation (status changes, close dates). Looking back 7 days ensures any late-arriving updates to existing records are captured — not just new records created today.

**Why MERGE over INSERT OVERWRITE?**
MERGE preserves historical records while updating changed ones. INSERT OVERWRITE would require reloading the entire dataset on every run, which is expensive and unnecessary for this use case.

---

## Airflow DAG

**DAG ID:** `austin_311_merge_manual`

| Property | Value |
|---|---|
| Schedule | None (manual trigger only) |
| Start Date | 2025-01-01 |
| Catchup | False |
| Operator | BigQueryInsertJobOperator |
| SQL Location | `/opt/airflow/sql/` via `template_searchpath` |

**Why manual trigger?**
This project uses manual DAG execution to avoid unnecessary BigQuery query costs during development and demonstration. In a production environment, this would be set to `schedule="@daily"`.

---

## Local Setup with Docker

The `docker-compose.yml` spins up 4 services:

| Service | Image | Purpose |
|---|---|---|
| postgres | postgres:15 | Airflow metadata database |
| airflow-webserver | apache/airflow:2.9.3 | Airflow UI on port 8080 |
| airflow-scheduler | apache/airflow:2.9.3 | DAG scheduling |
| airflow-init | apache/airflow:2.9.3 | DB init + admin user creation |

### How to Run Locally

1. Clone the repo:
```bash
git clone https://github.com/sumanlamichhane984/austin-311-data-engineering-pipeline.git
cd austin-311-data-engineering-pipeline
```

2. Add your GCP service account key:
```bash
# Place your key file in the project root
# Add to docker-compose.yml under volumes:
# - ./your-key.json:/opt/airflow/keys/gcp-key.json
# Set env: GOOGLE_APPLICATION_CREDENTIALS=/opt/airflow/keys/gcp-key.json
```

3. Start Airflow:
```bash
docker-compose up airflow-init
docker-compose up -d
```

4. Open Airflow UI:
```
http://localhost:8080
Username: admin
Password: admin
```

5. Trigger the DAG manually:
   - Find `austin_311_merge_manual` in the DAG list
   - Click the **Play** button to trigger a manual run
   - Monitor the task in Graph View

6. Verify results in BigQuery Console:
```sql
SELECT COUNT(*) FROM `austin_data_sets.raw_austin_311`;
```

---

## Cost Optimization Notes

- **Manual schedule** — No automatic runs means no unexpected BigQuery costs
- **7-day window** — Only queries recent data instead of scanning the full public dataset
- **MERGE over full reload** — Processes only changed/new records, minimizing bytes scanned
- **LocalExecutor** — No need for CeleryExecutor or Kubernetes for single-machine development

---

## Challenges & Lessons Learned

- **SQL template loading** — Using `template_searchpath` in the DAG instead of inline SQL keeps the DAG code clean and makes the SQL independently testable
- **Date casting** — The public dataset stores dates as TIMESTAMP, so explicit `DATE()` casting is required in the MERGE source query to match the destination schema
- **Docker volume mapping** — The `./sql:/opt/airflow/sql` volume mount is critical — without it, Airflow cannot find the SQL template file at runtime

---

## License

This project is licensed under the MIT License.
