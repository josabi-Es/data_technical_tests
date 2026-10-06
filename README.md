# Technical tests

This repository has the solution to two technical tests:

- Data Engineer: [`/data-engineer-test`](./data-engineer-test)
  - Technologies: Airbyte, PostgreSQL, dbt, Airflow, Docker and Python with uv.
- Data Analyst: [`/data-analyst-test`](./data-analyst-test)
  - Technologies: DuckDB, dbt, pandas, Jupyter, Streamlit, Docker (optional) and Python with uv.

## Data Engineer test

Everything is explained in [`/data-engineer-test/notes.md`](./data-engineer-test/notes.md): the problem, the decisions, the model, the tests and what is left. Start there.

The original brief is in [`/data-engineer-test/README.md`](./data-engineer-test/README.md).

### 1. Goal

Main objective: automation, configuration, coordination and execution.

- Load the CSV files with Airbyte into PostgreSQL and build the raw, staging and marts layers with dbt.
- Let Airflow run every step in the right order and on a schedule.
- See each run and its failures in Airflow.
- Deploy everything locally with Docker.

### 2. Prerequisites

- Install Airbyte: https://docs.airbyte.com/platform/using-airbyte/getting-started/oss-quickstart#part-2-install-abctl
- Install Docker: https://docs.docker.com/desktop/setup/install/windows-install/
- Install uv: https://docs.astral.sh/uv/getting-started/installation/

### 3. Deploy locally

#### Step 0: Clone and install

```bash
git clone https://github.com/josabi-Es/data_technical_tests.git
cd data_technical_tests/data-engineer-test
uv venv
source .venv/Scripts/activate   # or .venv/bin/activate
uv sync
```

#### Step 1: Set the environment variables

```bash
copy .env.template .env
```

Fill in the variables that are requested.

#### Step 2: Build Docker

```bash
docker compose up -d --build
```

This starts postgres, pgadmin, files and airflow. The `files` service serves the CSV files on port 8001, which Airbyte reads. To stop everything:

```bash
docker compose down
```

#### Step 3: Start Airbyte and create the connections

Follow the instructions in [ingestion/airbyte](data-engineer-test/ingestion/airbyte). Use these YAML files:

- Builder (connector): [csv_files_http.yaml](data-engineer-test/ingestion/airbyte/builder/csv_files_http.yaml)
- Sources: [csv_files_http.yaml](data-engineer-test/ingestion/airbyte/sources/csv_files_http.yaml), [postgres.yaml](data-engineer-test/ingestion/airbyte/sources/postgres.yaml)
- Destination: [postgres.yaml](data-engineer-test/ingestion/airbyte/destinations/postgres.yaml)

#### Step 4: Run the pipeline

With Airflow: open `http://localhost:8080` and start the DAG `run_all`. It loads the data and then runs dbt. It also runs by itself every day at 06:00 UTC.

With dbt only:

```bash
cd dbt
set -a; . ../.env; set +a
export DBT_PROFILES_DIR=.
DBT_FULL_REFRESH=true dbt build
```

You should see `PASS=127 WARN=3 ERROR=0`. The 3 warnings are normal. They are real findings in the data. Use `DBT_FULL_REFRESH=true` on the first run and after a schema change. Later runs are a plain `dbt build`.

### 4. External sources

- Airbyte: https://docs.airbyte.com/ and https://github.com/airbytehq/airbyte
- dbt: https://docs.getdbt.com/docs/get-started-dbt

## Data Analyst test

In this repository you can also find the solution to the Data Analyst test in [`/data-analyst-test`](./data-analyst-test).

It loads 10 CSV files into DuckDB and builds raw, staging and marts with dbt. A Streamlit dashboard shows the result.

Everything is explained, with demonstrations, in [`/data-analyst-test/notes.md`](./data-analyst-test/notes.md).

### Deploy locally

You need [uv](https://docs.astral.sh/uv/getting-started/installation/).

#### Step 0: Clone and install

```bash
git clone https://github.com/josabi-Es/data_technical_tests.git
cd data_technical_tests/data-analyst-test
uv venv
source .venv/Scripts/activate   # or .venv/bin/activate
uv sync
```

#### Step 1: Set the environment variables

```bash
copy .env.template .env
```

This file is optional. It has the folder of the CSV files and the path of the DuckDB file. Both already have a value.

#### Step 2: Load the raw data

```bash
uv run python src/ingest/ingest.py
```

This copies the 10 CSV files into the `raw` schema of DuckDB. The JSON files in `src/ingest/schema` say which columns and types to use. The log shows ok or failed for each table.

#### Step 3: Build staging and marts

```bash
uv run dbt build --project-dir src/dbt --profiles-dir src/dbt
```

You should see `PASS=183 WARN=3 ERROR=0`. The 3 warnings are normal. They are real findings in the data: 2 campaigns end before they start, 12 routes have no main worker and 137 visits not done have answers.

#### Step 4: Open the dashboard

```bash
uv run streamlit run dashboard/app.py
```

It opens `http://localhost:8501`.
