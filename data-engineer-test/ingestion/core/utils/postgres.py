import os

from sqlalchemy import create_engine, text


class Postgres:
    def __init__(self):
        url = (
            f"postgresql+psycopg2://{os.environ['POSTGRES_USER']}:{os.environ['POSTGRES_PASSWORD']}"
            f"@{os.environ['POSTGRES_HOST']}:{os.environ['POSTGRES_PORT']}/{os.environ['POSTGRES_DB']}"
        )
        self.engine = create_engine(url)
        with self.engine.connect() as conn:
            conn.execute(text("SELECT 1"))

    def create_raw_table(self, table, columns, primary_key):
        cols_sql = ", ".join(f'"{c}" text' for c in columns)
        with self.engine.begin() as conn:
            conn.execute(text("CREATE SCHEMA IF NOT EXISTS raw"))
            conn.execute(text(f'CREATE TABLE IF NOT EXISTS raw."{table}" ({cols_sql}, PRIMARY KEY ("{primary_key}"))'))
            has_key = conn.execute(
                text("select 1 from pg_constraint where conrelid = cast(:name as regclass) and contype = 'p'"),
                {"name": f'raw."{table}"'},
            ).first()
            if not has_key:
                conn.execute(text(f'ALTER TABLE raw."{table}" ADD PRIMARY KEY ("{primary_key}")'))

    def default_airbyte_columns(self, table):
        defaults = {
            "_airbyte_raw_id": "gen_random_uuid()::text",
            "_airbyte_extracted_at": "now()",
            "_airbyte_meta": "'{}'::jsonb",
            "_airbyte_generation_id": "0",
        }
        with self.engine.begin() as conn:
            for col, default in defaults.items():
                found = conn.execute(
                    text("select 1 from information_schema.columns where table_schema = 'raw' and table_name = :t and column_name = :c"),
                    {"t": table, "c": col},
                ).first()
                if found:
                    conn.execute(text(f'ALTER TABLE raw."{table}" ALTER COLUMN "{col}" SET DEFAULT {default}'))

    def load_rows(self, table, columns, rows):
        placeholders = ", ".join(f":{c}" for c in columns)
        col_names = ", ".join(f'"{c}"' for c in columns)
        with self.engine.begin() as conn:
            conn.execute(text(f'DELETE FROM raw."{table}"'))
            conn.execute(
                text(f'INSERT INTO raw."{table}" ({col_names}) VALUES ({placeholders})'),
                [dict(zip(columns, row)) for row in rows],
            )

    def close(self):
        self.engine.dispose()
