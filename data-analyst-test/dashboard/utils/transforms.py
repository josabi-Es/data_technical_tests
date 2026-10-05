import pandas as pd

from utils.labels import EXECUTED_STATUSES

CAMPAIGN_ATTRS = {
    "client_name": "client",
    "campaign_name": "campaign",
    "project_type": "type",
    "campaign_end_date": "end",
}


def safe_rate(num: float, den: float) -> float | None:
    return num / den if den else None


def fmt_pct(value: float | None) -> str:
    return f"{value:.1%}" if value is not None and pd.notna(value) else "n/a"


def visit_counts(visits: pd.DataFrame) -> dict:
    # pos is a distinct count, it does not add up across campaigns
    counts = visits["visit_status"].value_counts()
    done = visits[visits["visit_status"].isin(EXECUTED_STATUSES)]
    return {
        "recorded": len(visits),
        "done": len(done),
        "ok": int(counts.get("OK", 0)),
        "incid": int(counts.get("INCID", 0)),
        "novis": int(counts.get("NOVIS", 0)),
        "pos": done["intervention_point_id"].nunique(),
        "billable": int(visits["is_client_billable"].fillna(False).sum()),
    }


def visits_by_month_status(visits: pd.DataFrame) -> pd.DataFrame:
    monthly = (
        visits.dropna(subset=["visit_month"])
        .groupby(["visit_month", "visit_status"])
        .size()
        .reset_index(name="visits")
    )
    monthly["pct_visits"] = monthly["visits"] / monthly.groupby("visit_month")["visits"].transform("sum")
    return monthly


def visits_by_client(visits: pd.DataFrame) -> pd.DataFrame:
    done = visits[visits["visit_status"].isin(EXECUTED_STATUSES)]
    return done.groupby("client_name").size().reset_index(name="visits")


def campaign_table(campaigns: pd.DataFrame, visits: pd.DataFrame) -> pd.DataFrame:
    # counted from the filtered visits, so the month filter applies here too
    done = visits[visits["visit_status"].isin(EXECUTED_STATUSES)]
    agg = done.groupby("campaign_id").agg(
        visits=("visit_id", "count"),
        points=("intervention_point_id", "nunique"),
        routes=("route_id", "nunique"),
        last_visit=("visit_date", "max"),
    )
    base = campaigns.set_index("campaign_id")[list(CAMPAIGN_ATTRS)].rename(columns=CAMPAIGN_ATTRS)
    table = base.join(agg).rename(columns={"last_visit": "last visit"})
    table[["visits", "points", "routes"]] = table[["visits", "points", "routes"]].fillna(0).astype(int)
    return table.sort_values("visits", ascending=False).reset_index(drop=True)
