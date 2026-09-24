from datetime import datetime, timedelta

from airflow.sdk import DAG
from utils.steps import DEFAULT_ARGS, INGESTION_PARAMS, dbt_tasks, ingestion_tasks

with DAG(
    dag_id="run_all",
    description="Load raw, then dbt on staging, then dbt on marts",
    schedule="0 6 * * *",
    start_date=datetime(2026, 1, 1),
    catchup=False,
    max_active_runs=1,
    dagrun_timeout=timedelta(hours=1),
    default_args=DEFAULT_ARGS,
    params=INGESTION_PARAMS,
    tags=["ingestion", "dbt"],
) as dag:
    _, ingestion_done = ingestion_tasks()
    dbt_staging, _ = dbt_tasks()
    ingestion_done >> dbt_staging
