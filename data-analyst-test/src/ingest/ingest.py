import json
import logging
import os
import sys
from pathlib import Path

import duckdb
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[2]
SCHEMA_DIR = Path(__file__).parent / "schema"
DATE_FORMATS = ["%Y-%m-%d", "%d/%m/%Y"]
ALLOWED_TYPES = {"VARCHAR", "INTEGER", "BIGINT", "DOUBLE", "BOOLEAN", "DATE", "TIME", "TIMESTAMP"}

load_dotenv(ROOT / ".env")
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s", datefmt="%H:%M:%S")
log = logging.getLogger("ingest")


def resolve_path(env_name: str, default: str) -> Path:
    path = Path(os.getenv(env_name, default))
    return path if path.is_absolute() else ROOT / path


def load_schema(path: Path) -> dict[str, str]:
    columns = {name: dtype.upper() for name, dtype in json.loads(path.read_text(encoding="utf-8")).items()}
    unknown = {name: dtype for name, dtype in columns.items() if dtype not in ALLOWED_TYPES}
    if unknown:
        raise ValueError(f"unknown types {unknown}")
    return columns


def column_expr(column: str, dtype: str) -> str:
    name = f'"{column}"'
    if dtype == "VARCHAR":
        return name
    if dtype == "DATE":
        parsed = ", ".join(f"try_strptime({name}, '{fmt}')" for fmt in DATE_FORMATS)
        return f"coalesce({parsed})::DATE"
    return f"try_cast({name} as {dtype})"


def ingest_table(
    con: duckdb.DuckDBPyConnection, table: str, columns: dict[str, str], csv_path: Path
) -> tuple[int, dict[str, int]]:
    source = f"read_csv('{csv_path.as_posix()}', all_varchar=true)"
    header = con.sql(f"select * from {source} limit 0").columns
    missing = [name for name in columns if name not in header]
    if missing:
        raise ValueError(f"columns not in csv {missing}")

    select = ", ".join(f'{column_expr(name, dtype)} as "{name}"' for name, dtype in columns.items())
    con.sql(f"create or replace table raw.{table} as select {select} from {source}")

    # count failed casts
    typed = [name for name, dtype in columns.items() if dtype != "VARCHAR"]
    failed: dict[str, int] = {}
    if typed:
        checks = ", ".join(
            f'count(*) filter (where "{name}" is not null and {column_expr(name, columns[name])} is null)'
            for name in typed
        )
        counts = con.sql(f"select {checks} from {source}").fetchone()
        failed = {name: count for name, count in zip(typed, counts) if count}
    rows = con.sql(f"select count(*) from raw.{table}").fetchone()[0]
    return rows, failed


def main() -> None:
    raw_dir = resolve_path("RAW_DATA_DIR", "data/raw")
    db_path = resolve_path("DUCKDB_PATH", "data/duckDB/primer_impacto.duckdb")
    schema_files = sorted(SCHEMA_DIR.glob("*.json"))
    if not schema_files:
        log.error("no schema files in %s", SCHEMA_DIR)
        sys.exit(1)

    log.info("start, %d tables, db %s", len(schema_files), db_path.name)
    try:
        db_path.parent.mkdir(parents=True, exist_ok=True)
        con = duckdb.connect(str(db_path))
        con.sql("create schema if not exists raw")
    except (duckdb.Error, OSError) as exc:
        log.error("db open failed: %s", exc)
        sys.exit(1)

    failed_tables = []
    cast_failed_tables = []
    for schema_file in schema_files:
        table = schema_file.stem
        try:
            csv_path = raw_dir / f"{table}.csv"
            if not csv_path.exists():
                raise FileNotFoundError(f"csv not found {csv_path}")
            rows, failed = ingest_table(con, table, load_schema(schema_file), csv_path)
        except (duckdb.Error, OSError, ValueError) as exc:
            failed_tables.append(table)
            log.error("%s failed: %s", table, exc)
            continue
        log.info("%s ok, %d rows", table, rows)
        for name, count in failed.items():
            log.error("%s.%s, %d values not converted", table, name, count)
        if failed:
            cast_failed_tables.append(table)
    con.close()

    if failed_tables or cast_failed_tables:
        log.error("done with errors, failed: %s", ", ".join(failed_tables + cast_failed_tables))
        sys.exit(1)
    log.info("done, all %d tables ok", len(schema_files))


if __name__ == "__main__":
    main()
