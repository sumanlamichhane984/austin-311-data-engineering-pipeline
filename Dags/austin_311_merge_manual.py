from datetime import datetime

from airflow import DAG
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator

with DAG(
    dag_id="austin_311_merge_manual",
    start_date=datetime(2025, 1, 1),
    schedule=None,  # manual only (no automatic runs)
    catchup=False,
    template_searchpath=["/opt/airflow/sql"],  # <-- where Airflow looks for SQL files
    tags=["bigquery", "manual"],
) as dag:

    merge_last_7_days = BigQueryInsertJobOperator(
        task_id="merge_last_7_days",
        location="US",
        configuration={
            "query": {
                "query": "{% include 'merge_austin_311_last_7_days.sql' %}",
                "useLegacySql": False,
            }
        },
    )
