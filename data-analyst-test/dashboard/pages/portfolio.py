import plotly.express as px
import streamlit as st
from utils.data import load_campaigns, load_visits
from utils.filters import apply_filters, apply_month
from utils.transforms import (
    fmt_pct,
    safe_rate,
    visit_counts,
    visits_by_client,
    visits_by_month_status,
)

NOT_DONE = "Status NOVIS, the worker did not carry out the visit"
POS = "Points of sale with at least one visit, counted once"


def render(filters: dict) -> None:
    campaigns = apply_filters(load_campaigns(), filters)
    all_visits = apply_filters(load_visits(), filters)
    visits = apply_month(all_visits, filters)

    st.title("Portfolio")

    v = visit_counts(visits)

    with st.container(border=True):
        c1, c2, c3, c4, c5 = st.columns(5)
        c1.metric("Clients", campaigns["client_name"].nunique())
        c2.metric("Campaigns", len(campaigns), f"{(campaigns['campaign_phase'] == 'Active').sum()} active")
        c3.metric("Visits done", f"{v['done']:,}", help="Status OK, INCID or INFO")
        c4.metric("Points covered", v["pos"], help=POS)
        c5.metric("Not done", fmt_pct(safe_rate(v["novis"], v["recorded"])), help=NOT_DONE)

    left, right = st.columns(2)

    with left, st.container(border=True):
        st.subheader("Visits by client")
        fig = px.bar(
            visits_by_client(visits), x="visits", y="client_name",
            orientation="h", labels={"client_name": "", "visits": "visits done"},
        )
        fig.update_yaxes(categoryorder="total ascending")
        st.plotly_chart(fig, width="stretch")

    with right, st.container(border=True):
        st.subheader("Visits by month")
        st.caption("Every month, the month filter does not apply here")
        fig = px.bar(
            visits_by_month_status(all_visits), x="visit_month", y="visits", color="visit_status",
            labels={"visit_month": "", "visits": "visits", "visit_status": "status"},
        )
        st.plotly_chart(fig, width="stretch")
