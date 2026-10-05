# Technical tests

This repository has the solution to two technical tests:

- Data Engineer: [`/data-engineer-test`](./data-engineer-test)
  - Technologies: Airbyte, PostgreSQL, dbt, Airflow, Docker and Python with uv.
- Data Analyst: [`/data-analyst-test`](./data-analyst-test)
  - Technologies: DuckDB, dbt, pandas, Jupyter, Streamlit, Docker (optional) and Python with uv.

## Data Engineer test

In this repository you can find the solution to the Data Engineer test in [`/data-engineer-test`](./data-engineer-test).

### 1. Goal

Main objective: automation, configuration, coordination and execution.

- Automate the whole process: load the CSV files with Airbyte and run dbt inside a PostgreSQL database.
- Build the raw, staging and marts layers in PostgreSQL.
- Let Airflow run every step in the right order and on a schedule.
- Track how long each run takes and when it fails.
- Deploy everything locally with Docker.

The focus is the pipeline: how the data moves, how it runs and how it is monitored.

### 2. Prerequisites

- Install Airbyte: https://docs.airbyte.com/platform/using-airbyte/getting-started/oss-quickstart#part-2-install-abctl
- Install Docker: https://docs.docker.com/desktop/setup/install/windows-install/
- Install uv: https://docs.astral.sh/uv/getting-started/installation/

### 3. Instructions

All the instructions are in [`/data-engineer-test/README.md`](./data-engineer-test/README.md). That document was not modified. It is the original.

### 4. Extra documentation

This project has 3 phases: Ingestion, dbt and orchestration with Airflow.

In the folder `/data-engineer-test/docs` you can find detailed information about each phase. There is also an `introduccion.md` file with the first approach.

To see the decisions and the specifications of the project, go to:

- `/docs/airflow.md`
- `/docs/ingestion.md`
- `/docs/dbt.md`

### 5. Deploy locally

#### Step 0: Clone and install

```bash
git clone https://github.com/josabi-Es/data_technical_tests.git
cd data-engineer-test
uv venv
source .venv/Scripts/activate   # or .venv/bin/activate
uv sync
```

#### Step 1: Set the environment variables

```bash
cd data-engineer-test
copy .env.template .env
```

Fill in the variables that are requested.

#### Step 2: Build Docker

Build and start the containers with Docker Compose.

```bash
cd data-engineer-test
docker compose up -d --build
```

This starts postgres, pgadmin, files and airflow. To stop them:

```bash
docker compose down
```

#### Step 3: Start the HTTP endpoint

```bash
uv run python -m ingestion.http.serve_http
```

This leaves an open endpoint that a terminal can read.

#### Step 4: Start Airbyte and create the connections

Follow the instructions in [ingestion/airbyte](data-engineer-test/ingestion/airbyte). Use these YAML files:

- Builder (connector): [csv_files_http.yaml](data-engineer-test/ingestion/airbyte/builder/csv_files_http.yaml)
- Sources: [csv_files_http.yaml](data-engineer-test/ingestion/airbyte/sources/csv_files_http.yaml), [postgres.yaml](data-engineer-test/ingestion/airbyte/sources/postgres.yaml)
- Destination: [postgres.yaml](data-engineer-test/ingestion/airbyte/destinations/postgres.yaml)

#### Step 5: Test the configuration

Test the configuration with the DAGs in `localhost:8000`.

If you leave this setup running, you can schedule periodic ingestions and periodic transformations. They are controlled by Airbyte and by the Airflow schedule.

### 6. External sources

Source external used 

- Ingestion: 
- https://docs.airbyte.com/
- https://docs.airbyte.com/platform/using-airbyte/getting-started/oss-quickstart
- https://github.com/airbytehq/airbyte

dbt
- https://docs.getdbt.com/docs/get-started-dbt
- https://github.com/airbytehq/airbyte

## Data Analyst test

In this repository you can also find the solution to the Data Analyst test in [`/data-analyst-test`](./data-analyst-test).

It loads 10 CSV files into DuckDB and builds raw, staging and marts with dbt. A Streamlit dashboard shows the result.

Everything is explained, with demonstrations, in [`/data-analyst-test/notes.md`](./data-analyst-test/notes.md).

### Deploy locally

You need [uv](https://docs.astral.sh/uv/getting-started/installation/). Docker is optional and only used in Step 5.

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

#### Step 5: Run the dashboard with Docker (optional)

If you prefer a container, build the image and run it. The database is not inside the image, so the `data` folder is shared with the container.

```bash
docker build -f dashboard/dockerfile -t analyst-dashboard .
docker run -p 8501:8501 -v "${PWD}/data:/app/data" analyst-dashboard
```

Open `http://localhost:8501`. Run Step 2 and Step 3 first, so the database exists.
