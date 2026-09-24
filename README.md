# Technical test

In this repository you can find the solution to the Data Engineer test in [`/data-engineer-test`](./data-engineer-test).

## Prerequisites

- Install Airbyte.
- Install Docker: https://docs.docker.com/desktop/setup/install/windows-install/
- Install uv.

## Instructions

All the instructions are in [`/data-engineer-test/README.md`](./data-engineer-test/README.md). That document was not modified. It is the original.

## Extra documentation

This project has 3 phases: Ingestion, dbt and orchestration with Airflow.

In the folder `/data-engineer-test/docs` you can find detailed information about each phase. There is also an `introduccion.md` file with the first approach.

To see the decisions and the specifications of the project, go to:

- `/docs/airflow.md`
- `/docs/ingestion.md`
- `/docs/dbt.md`
- `/docs/init.md`  <-- See architecture below for a clearer overview

## Deploy locally

### Step 0: Clone and install

```bash
git clone https://github.com/josabi-Es/data_technical_tests.git
cd data-engineer-test
uv venv
source .venv/Scripts/activate   # or .venv/bin/activate
uv sync
```

### Step 1: Set the environment variables

```bash
cd data-engineer-test
copy .env.template .env
```

Fill in the variables that are requested.

### Step 2: Build Docker

Build and start the containers with Docker Compose.

```bash
cd data-engineer-test
docker compose up -d --build
```

### Step 3: Start the HTTP endpoint

```bash
uv run python -m ingestion.http.serve_http
```

This leaves an open endpoint that a terminal can read.

### Step 4: Start Airbyte and create the connections

Follow the instructions in [ingestion/airbyte](data-engineer-test/ingestion/airbyte). Use these YAML files:

- Builder (connector): [csv_files_http.yaml](data-engineer-test/ingestion/airbyte/builder/csv_files_http.yaml)
- Sources: [csv_files_http.yaml](data-engineer-test/ingestion/airbyte/sources/csv_files_http.yaml), [postgres.yaml](data-engineer-test/ingestion/airbyte/sources/postgres.yaml)
- Destination: [postgres.yaml](data-engineer-test/ingestion/airbyte/destinations/postgres.yaml)

### Step 5: Test the configuration

Test the configuration with the DAGs in `localhost:8000`.

If you leave this setup running, you can schedule periodic ingestions and periodic transformations. They are controlled by Airbyte and by the Airflow schedule.

## Goal

- Get the connections working.
- Link everything and deploy it locally.
- Build an example data model.
- Get the raw, staging and marts structure in the database I chose, with the schedule controlled and with times and possible failures tracked.


Source external used 

Ingestion
- https://docs.airbyte.com/
- https://docs.airbyte.com/platform/using-airbyte/getting-started/oss-quickstart
- https://github.com/airbytehq/airbyte

dbt
- https://docs.getdbt.com/docs/get-started-dbt
- https://github.com/dbt-labs/dbt
- https://github.com/dbt-labs/jaffle-shop

Dags
- https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/dags.html
- https://github.com/josabi-Es/MadridSmartData

