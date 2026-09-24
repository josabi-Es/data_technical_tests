from datetime import datetime

from airflow.sdk import DAG
from utils.steps import DEFAULT_ARGS, dbt_tasks

with DAG(
    dag_id="raw_stg_marts",
    description="dbt: raw to staging, then staging to marts",
    schedule=None,
    start_date=datetime(2026, 1, 1),
    catchup=False,
    default_args=DEFAULT_ARGS,
    tags=["dbt"],
) as dag:
    dbt_tasks()
