import streamlit as st
from pages import campaigns, form_answers, portfolio, team
from utils.filters import sidebar_filters

st.set_page_config(page_title="Primer Impacto", layout="wide")

filters = sidebar_filters()

# each page is a render function
nav = st.navigation([
    st.Page(lambda: portfolio.render(filters), title="Portfolio", url_path="portfolio", default=True),
    st.Page(lambda: campaigns.render(filters), title="Campaigns", url_path="campaigns"),
    st.Page(lambda: team.render(filters), title="Routes and team", url_path="routes-team"),
    st.Page(lambda: form_answers.render(filters), title="Form answers", url_path="form-answers"),
])
nav.run()
