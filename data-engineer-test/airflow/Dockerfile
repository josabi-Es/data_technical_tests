FROM apache/airflow:3.1.5

RUN mkdir -p /opt/airflow/state

RUN python -m venv /home/airflow/tools_venv \
    && /home/airflow/tools_venv/bin/pip install --no-cache-dir \
        dbt-core==1.12.5 \
        dbt-postgres==1.11.0 \
        psycopg2-binary==2.9.13 \
        sqlalchemy==2.0.54 \
        python-dotenv==1.2.3
