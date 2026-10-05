import plotly.express as px
import streamlit as st
from utils.data import (
    count_workers_without_route,
    load_routes,
    load_visits,
    load_workers,
)
from utils.filters import apply_filters, apply_month

PERCENT = st.column_config.NumberColumn(format="percent", step=0.01)
FLOOR = "Visits count for the main worker of each route, so this is a floor"

TABLE_COLUMNS = {
    "employee_first_name": "worker",
    "employee_address_province": "province",
    "routes_assigned": "routes",
    "total_visits_done": "visits",
    "visits_per_active_day": "visits per day",
    "success_rate": "ok",
    "incident_rate": "incident",
    "no_show_rate": "not done",
    "form_completion_rate": "form",
    "routes_without_visits": "empty routes",
}


def render(filters: dict) -> None:
    routes = apply_filters(load_routes(), filters)
    workers = load_workers()
    visits = apply_month(apply_filters(load_visits(), filters), filters)

    st.title("Routes and team")

    started = routes[routes["route_start_date"] <= routes["reference_date"]]
    with_visits = (started["total_visits"] > 0).sum()
    empty_closed = int(routes["is_closed_without_visits"].sum())

    with st.container(border=True):
        c1, c2, c3, c4, c5 = st.columns(5)
        c1.metric("Routes started", len(started), f"of {len(routes)} routes")
        c2.metric("With visits", with_visits,
                  help="Routes that recorded at least one visit")
        c3.metric("Closed empty", empty_closed,
                  help="Route period ended with no visit recorded")
        c4.metric("Workers on a route", len(workers),
                  f"{count_workers_without_route()} without a route")
        c5.metric("Visits per day", f"{workers['visits_per_active_day'].mean():.1f}", help=FLOOR)

    with st.container(border=True):
        st.subheader("Workers")
        st.caption("Every worker, the client filter does not apply here")
        table = workers.rename(columns=TABLE_COLUMNS)
        st.dataframe(
            table[list(TABLE_COLUMNS.values())],
            width="stretch",
            hide_index=True,
            column_config={c: PERCENT for c in ["ok", "incident", "not done", "form"]},
        )

    left, right = st.columns(2)

    with left, st.container(border=True):
        st.subheader("Empty routes by delegation")
        by_delegation = (
            routes[routes["is_closed_without_visits"]]
            .groupby("delegation_code").size().reset_index(name="routes")
        )
        fig = px.bar(by_delegation, x="routes", y="delegation_code",
                     orientation="h", labels={"delegation_code": ""})
        fig.update_yaxes(categoryorder="total ascending")
        st.plotly_chart(fig, width="stretch")

    with right, st.container(border=True):
        st.subheader("Visits by province")
        st.caption("Province of the point of sale")
        by_province = (
            visits.dropna(subset=["province"]).groupby("province").size()
            .reset_index(name="visits").nlargest(12, "visits")
        )
        fig = px.bar(by_province, x="visits", y="province",
                     orientation="h", labels={"province": ""})
        fig.update_yaxes(categoryorder="total ascending")
        st.plotly_chart(fig, width="stretch")
