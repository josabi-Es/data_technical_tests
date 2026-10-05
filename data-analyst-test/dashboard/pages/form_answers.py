import plotly.express as px
import streamlit as st
from utils.data import load_responses
from utils.filters import apply_filters, apply_month

DONE_ONLY = "Only visits that were done, NOVIS and UNKNOWN are left out"


def render(filters: dict) -> None:
    responses = apply_month(apply_filters(load_responses(), filters), filters)
    responses = responses[~responses["visit_status"].isin(["NOVIS", "UNKNOWN"])]

    st.title("Form answers")

    facings = responses[responses["question_name"].str.contains("facings de", case=False, na=False)].copy()
    facings["product"] = facings["question_name"].str.extract(r"facings de (.*)$", expand=False)
    facings["facings"] = facings["answer"].str.extract(r"^(\d+)", expand=False).astype(float)

    training = responses[responses["question_name"].str.contains("Resultado de la formaci", case=False, na=False)]
    orders = responses[responses["question_name"].str.contains("quiere realizar pedido", case=False, na=False)]
    orders = orders[orders["answer"].isin(["Si", "No"])]

    trained = (training["answer"].str.contains("OK", na=False)).mean() if len(training) else None
    order_rate = (orders["answer"] == "Si").mean() if len(orders) else None

    with st.container(border=True):
        c1, c2, c3 = st.columns(3)
        c1.metric(
            "Facings per answer",
            f"{facings['facings'].mean():.1f}" if facings["facings"].notna().any() else "n/a",
            help=f"Average units on shelf. {DONE_ONLY}",
        )
        c2.metric("Training accepted", f"{trained:.1%}" if trained is not None else "n/a",
                  f"{len(training)} answers", help=DONE_ONLY)
        c3.metric("Points that order", f"{order_rate:.1%}" if order_rate is not None else "n/a",
                  f"{len(orders)} answers", help=DONE_ONLY)

    left, right = st.columns(2)

    with left, st.container(border=True):
        st.subheader("Facings by product")
        by_product = facings.groupby("product")["facings"].mean().round(1).reset_index().dropna()
        fig = px.bar(by_product, x="facings", y="product", orientation="h", labels={"product": ""})
        fig.update_yaxes(categoryorder="total ascending")
        st.plotly_chart(fig, width="stretch")

    with right, st.container(border=True):
        st.subheader("Training results")
        result = training["answer"].value_counts().reset_index()
        result.columns = ["result", "answers"]
        fig = px.bar(result, x="answers", y="result", orientation="h", labels={"result": ""})
        fig.update_yaxes(categoryorder="total ascending")
        st.plotly_chart(fig, width="stretch")
