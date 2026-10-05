import plotly.express as px
import streamlit as st
from utils.data import load_campaigns, load_visits
from utils.filters import apply_filters, apply_month
from utils.transforms import campaign_table, fmt_pct, safe_rate, visit_counts

DATE = st.column_config.DateColumn(format="DD MMM YYYY")

COLUMN_CONFIG = {
    "end": DATE,
    "last visit": DATE,
    "visits": st.column_config.NumberColumn(help="Visits done, status OK, INCID or INFO"),
    "points": st.column_config.NumberColumn(help="Points of sale reached"),
    "routes": st.column_config.NumberColumn(help="Routes with at least one visit"),
}


def render(filters: dict) -> None:
    campaigns = apply_filters(load_campaigns(), filters)
    visits = apply_month(apply_filters(load_visits(), filters), filters)

    st.title("Campaigns")

    v = visit_counts(visits)
    empty = (campaigns["total_visits_done"] == 0).sum()

    with st.container(border=True):
        c1, c2, c3, c4, c5 = st.columns(5)
        c1.metric("Campaigns", len(campaigns), f"{empty} with no visit")
        c2.metric("Visits done", f"{v['done']:,}", help="Status OK, INCID or INFO")
        c3.metric("OK", fmt_pct(safe_rate(v["ok"], v["recorded"])), help="Share of recorded visits")
        c4.metric("Incident", fmt_pct(safe_rate(v["incid"], v["recorded"])), help="Share of recorded visits")
        c5.metric("Not done", fmt_pct(safe_rate(v["novis"], v["recorded"])), help="Share of recorded visits")

    with st.container(border=True):
        st.subheader("Campaign list")
        st.dataframe(
            campaign_table(campaigns, visits),
            width="stretch",
            hide_index=True,
            column_config=COLUMN_CONFIG,
        )

    with st.container(border=True):
        st.subheader("Visit result by campaign")
        st.caption("Top 15 campaigns by visits done")
        top = campaigns.nlargest(15, "total_visits_done")
        mix = top.melt(
            id_vars="campaign_name",
            value_vars=["visits_ok", "visits_incid", "visits_info", "visits_novis"],
            var_name="status", value_name="visits",
        )
        mix["status"] = mix["status"].str.replace("visits_", "", regex=False).str.upper()
        fig = px.bar(mix, x="visits", y="campaign_name", color="status",
                     orientation="h", labels={"campaign_name": "", "visits": "visits"})
        fig.update_yaxes(categoryorder="total ascending")
        st.plotly_chart(fig, width="stretch")
