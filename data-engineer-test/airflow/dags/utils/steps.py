import logging
import os
import time
from datetime import timedelta

import requests
from airflow.providers.smtp.notifications.smtp import send_smtp_notification
from airflow.providers.standard.operators.bash import BashOperator
from airflow.providers.standard.operators.empty import EmptyOperator
from airflow.sdk import Param, TriggerRule, task

log = logging.getLogger(__name__)

TOOLS = "/home/airflow/tools_venv/bin"
DBT_BUILD = f"{TOOLS}/dbt build --project-dir /opt/airflow/dbt --profiles-dir /opt/airflow/dbt"


def notify_failure(context):
    ti = context["ti"]
    log.error("PIPELINE FAILED: dag=%s task=%s run=%s", ti.dag_id, ti.task_id, ti.run_id)


def failure_callbacks():
    callbacks = [notify_failure]
    alert_to = os.environ.get("ALERT_TO")
    if alert_to:
        callbacks.append(
            send_smtp_notification(
                to=alert_to,
                subject="[Airflow] {{ ti.dag_id }} failed at {{ ti.task_id }}",
                html_content="The task {{ ti.task_id }} of the DAG {{ ti.dag_id }} failed. Run: {{ ti.run_id }}.",
            )
        )
    return callbacks


DEFAULT_ARGS = {
    "retries": 2,
    "retry_delay": timedelta(minutes=2),
    "execution_timeout": timedelta(minutes=15),
    "on_failure_callback": failure_callbacks(),
}

AIRBYTE_API = os.environ.get("AIRBYTE_API_URL", "http://host.docker.internal:8000/api/public/v1")
AIRBYTE_SOURCE = "csv_files_http_typed"

INGESTION_PARAMS = {
    "ingestion_mode": Param(
        "airbyte",
        type="string",
        enum=["python", "airbyte"],
        description="airbyte runs the sync of the csv_files_http_typed source. python loads the CSV files with ingestion.py.",
    )
}


def airbyte_sync():
    token = requests.post(
        f"{AIRBYTE_API}/applications/token",
        json={
            "client_id": os.environ["AIRBYTE_CLIENT_ID"],
            "client_secret": os.environ["AIRBYTE_CLIENT_SECRET"],
            "grant-type": "client_credentials",
        },
        timeout=30,
    )
    token.raise_for_status()
    session = requests.Session()
    session.headers["Authorization"] = f"Bearer {token.json()['access_token']}"

    def get(path):
        response = session.get(f"{AIRBYTE_API}{path}", timeout=30)
        response.raise_for_status()
        return response.json()

    source_ids = [s["sourceId"] for s in get("/sources?limit=100")["data"] if s["name"] == AIRBYTE_SOURCE]
    if not source_ids:
        raise ValueError(f"No Airbyte source named {AIRBYTE_SOURCE}")
    connections = [c for c in get("/connections?limit=100")["data"] if c["sourceId"] in source_ids]
    if len(connections) != 1:
        raise ValueError(f"Expected one connection for {AIRBYTE_SOURCE}, found {len(connections)}")

    job = session.post(
        f"{AIRBYTE_API}/jobs",
        json={"connectionId": connections[0]["connectionId"], "jobType": "sync"},
        timeout=30,
    )
    job.raise_for_status()
    job_id = job.json()["jobId"]
    log.info("Airbyte sync started: connection=%s job=%s", connections[0]["name"], job_id)

    # poll until the job ends
    while True:
        status = get(f"/jobs/{job_id}")["status"]
        if status == "succeeded":
            log.info("Airbyte sync succeeded: job=%s", job_id)
            return
        if status in ("failed", "cancelled", "incomplete"):
            raise RuntimeError(f"Airbyte sync {job_id} ended with status {status}")
        time.sleep(15)


def ingestion_tasks():
    @task.branch(task_id="choose_ingestion")
    def choose_ingestion(params=None):
        if params["ingestion_mode"] == "airbyte":
            return "ingest_airbyte"
        return "ingest_python"

    @task(task_id="ingest_airbyte")
    def ingest_airbyte():
        airbyte_sync()

    ingest_python = BashOperator(
        task_id="ingest_python",
        bash_command=f"{TOOLS}/python /opt/airflow/ingestion/core/ingestion.py",
    )

    ingestion_done = EmptyOperator(
        task_id="ingestion_done",
        trigger_rule=TriggerRule.NONE_FAILED_MIN_ONE_SUCCESS,
    )

    first = choose_ingestion()
    first >> [ingest_python, ingest_airbyte()] >> ingestion_done
    return first, ingestion_done


def dbt_tasks():
    dbt_staging = BashOperator(task_id="dbt_staging", bash_command=f"{DBT_BUILD} --select staging")
    dbt_marts = BashOperator(task_id="dbt_marts", bash_command=f"{DBT_BUILD} --select marts")
    dbt_staging >> dbt_marts
    return dbt_staging, dbt_marts
