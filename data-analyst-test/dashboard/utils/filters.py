import pandas as pd
import streamlit as st

from utils.data import load_campaigns, load_visits

ALL_CLIENTS = "All clients"
ALL_TYPES = "All types"
ALL_MONTHS = "All months"


def sidebar_filters() -> dict:
    campaigns = load_campaigns()
    # only months that have visits
    months = sorted(load_visits()["visit_month"].dropna().unique())
    with st.sidebar:
        st.header("Filters")

        client = st.selectbox(
            "Client", [ALL_CLIENTS] + sorted(campaigns["client_name"].dropna().unique())
        )

        # types available for the chosen client only
        scoped = campaigns if client == ALL_CLIENTS else campaigns[campaigns["client_name"] == client]
        types = sorted(scoped["project_type"].dropna().unique())
        project_type = st.selectbox("Project type", [ALL_TYPES] + types)

        month = st.selectbox(
            "Month",
            [ALL_MONTHS] + months,
            format_func=lambda v: v if v == ALL_MONTHS else f"{pd.Timestamp(v):%b %Y}",
            help="Changes visit figures only. Planned visits stay whole campaign",
        )

        st.caption(f"Data up to {campaigns['reference_date'].max():%d %b %Y}")

    return {"client": client, "project_type": project_type, "month": month}


def apply_filters(df: pd.DataFrame, filters: dict) -> pd.DataFrame:
    if filters["client"] != ALL_CLIENTS:
        df = df[df["client_name"] == filters["client"]]
    if filters["project_type"] != ALL_TYPES:
        df = df[df["project_type"] == filters["project_type"]]
    return df


def apply_month(df: pd.DataFrame, filters: dict) -> pd.DataFrame:
    # visit level frames only, never plan figures
    if filters["month"] == ALL_MONTHS:
        return df
    return df[df["visit_month"] == filters["month"]]
