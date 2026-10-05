import pandas as pd
import streamlit as st

from utils.db import query
from utils.labels import CAMPAIGN_STATE_EN, PROJECT_TYPE_EN


@st.cache_data
def load_campaigns() -> pd.DataFrame:
    # counts and campaign_phase are computed in sql, see the mart
    df = query("select * from marts.mart_campaign_performance")
    df["project_type"] = df["project_type"].replace(PROJECT_TYPE_EN)
    df["campaign_state"] = df["campaign_state"].replace(CAMPAIGN_STATE_EN)
    return df


@st.cache_data
def load_visits() -> pd.DataFrame:
    df = query("""
        select
            v.visit_id, v.campaign_id, v.route_id, v.intervention_point_id,
            v.visit_date, v.visit_status, v.is_client_billable,
            c.client_name, c.project_type, c.campaign_name,
            p.intervention_point_province as province
        from marts.fct_visits as v
        left join marts.mart_campaign_performance as c using (campaign_id)
        left join marts.dim_pos as p using (intervention_point_id)
    """)
    df["project_type"] = df["project_type"].replace(PROJECT_TYPE_EN)
    df["visit_month"] = pd.to_datetime(df["visit_date"]).dt.to_period("M").dt.to_timestamp()
    return df


@st.cache_data
def load_routes() -> pd.DataFrame:
    df = query("""
        select r.*, c.client_name, c.project_type
        from marts.mart_route_performance as r
        left join marts.mart_campaign_performance as c using (campaign_id)
    """)
    df["project_type"] = df["project_type"].replace(PROJECT_TYPE_EN)
    return df


@st.cache_data
def load_workers() -> pd.DataFrame:
    return query("select * from marts.mart_worker_performance order by total_visits_done desc")


@st.cache_data
def count_workers_without_route() -> int:
    return int(query("""
        select count(*) as n
        from marts.dim_worker as w
        left join marts.bridge_route_worker as b on w.employee_id = b.employee_id
        where b.employee_id is null
    """)["n"][0])


@st.cache_data
def load_responses() -> pd.DataFrame:
    df = query("""
        select m.visit_id, m.campaign_id, m.visit_status, m.visit_date,
               m.question_name, m.answer,
               c.client_name, c.project_type
        from marts.mart_visit_responses as m
        left join marts.mart_campaign_performance as c using (campaign_id)
    """)
    df["project_type"] = df["project_type"].replace(PROJECT_TYPE_EN)
    df["visit_month"] = pd.to_datetime(df["visit_date"]).dt.to_period("M").dt.to_timestamp()
    return df
