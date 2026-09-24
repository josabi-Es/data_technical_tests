from datetime import datetime

from airflow.sdk import DAG
from utils.steps import DEFAULT_ARGS, INGESTION_PARAMS, ingestion_tasks

with DAG(
    dag_id="ingest_raw",
    description="Load raw",
    schedule=None,
    start_date=datetime(2026, 1, 1),
    catchup=False,
    default_args=DEFAULT_ARGS,
    params=INGESTION_PARAMS,
    tags=["ingestion"],
) as dag:
    ingestion_tasks()
