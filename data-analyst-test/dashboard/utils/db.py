import os
from pathlib import Path

import duckdb
import pandas as pd
import streamlit as st
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[2]
load_dotenv(ROOT / ".env")
DEFAULT_DB = "data/duckDB/primer_impacto.duckdb"


def db_path() -> Path:
    # absolute paths win over ROOT
    return ROOT / os.getenv("DUCKDB_PATH", DEFAULT_DB)


@st.cache_resource
def get_connection() -> duckdb.DuckDBPyConnection:
    return duckdb.connect(str(db_path()), read_only=True)


def query(sql: str) -> pd.DataFrame:
    return get_connection().sql(sql).df()
