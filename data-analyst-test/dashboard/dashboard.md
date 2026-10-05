# Dashboard

Streamlit app over the `marts` layer in DuckDB. Four tabs, one per part of the
business question in the brief: how campaigns are performing, whether field
workers complete their routes, a portfolio view for management, and what the
client actually receives from the field.

The app only filters and displays. Every KPI is computed in SQL inside the
marts, so there is one definition per metric and it lives in dbt. See
`notes.md` sections 6 and 7.

**Filters** (sidebar, shared by all tabs): client, project type, month. One
value each. The project type list is built from the chosen client, so an empty
combination cannot be picked. The month filter changes visit figures only;
campaign attributes do not depend on a month.

**Reference date**: the latest visit date in the data, not today. The extract
is static, so today would make every campaign look finished.

## Tab map

| Tab | Question it answers | Gold tables it reads |
|---|---|---|
| Portfolio | Is the portfolio being delivered, and where is the work concentrated | `mart_campaign_performance`, `fct_visits`, `dim_pos` |
| Campaigns | Which campaigns deliver, and with what quality | `mart_campaign_performance`, `fct_visits`, `dim_pos` |
| Routes and team | Is the planned field work happening, and who is doing it | `mart_route_performance`, `mart_worker_performance`, `bridge_route_worker`, `dim_worker`, `fct_visits` |
| Form answers | What the client receives from each visit | `mart_visit_responses`, `mart_campaign_performance` |

`mart_campaign_performance` appears almost everywhere because it carries client
and project name. It is what makes the client and project type filters work on
every tab without joining again.

## Portfolio

Management view across clients and projects.

| Figure | What it tells the client |
|---|---|
| Clients, Campaigns (with active count) | Size of the portfolio and how much of it is live |
| Visits done | The delivery. Status `OK`, `INCID` or `INFO` |
| Points covered | Reach. Points of sale with at least one visit, counted once, so repeat visits do not inflate it |
| Not done | Share of `NOVIS`. Capacity that was paid for and lost |

Charts:

- Visits by client. Where the operation is concentrated, so a drop in one client is visible against the rest.
- Visits by month and status. Seasonality and whether the result mix changes over time. The month filter does not apply here on purpose, the whole series is the point.

Reads `mart_campaign_performance` for the campaign and client attributes, and
`fct_visits` joined to `dim_pos` for the visit level counts and the province.

## Campaigns

One campaign at a time, and the comparison between them.

| Figure | What it tells the client |
|---|---|
| Campaigns, with no visit | How many campaigns exist and how many never started in the field |
| Visits done | Delivery for the current filter |
| OK, Incident, Not done | Quality of the field work, as a share of recorded visits so `NOVIS` stays visible |

Charts:

- Campaign list. One row per campaign with visits, points, routes, end date and last visit. The operational detail a campaign manager asks for.
- Visit result by campaign, top 15 by visits done. Which campaigns carry incidents instead of clean visits.

Status shares use recorded visits as the base, not visits done. Otherwise
`NOVIS` would disappear from its own percentage.

## Routes and team

Execution and productivity.

| Figure | What it tells the client |
|---|---|
| Routes started, of total | How much of the plan has reached the field |
| With visits | Routes that recorded at least one visit |
| Closed empty | Route period ended with zero visits. Planned work that did not happen |
| Workers on a route, without a route | Team actually deployed versus idle |
| Visits per day | Average productivity. A floor, not an exact value, see below |

Charts:

- Workers table. Per person: routes, visits, visits per day, `OK`, incident and not done rates, form completion, empty routes. Who performs and who needs support.
- Empty routes by delegation. Where the waste is, so it can be addressed by office.
- Visits by province, from the point of sale. Where to put the team.

A visit belongs to a route, and a route can have several workers. Visits are
attributed to the main worker of the route (`main_employee` in
`bridge_route_worker`), so a visit is never counted twice. That makes the per
worker figures a floor: a secondary worker on the route gets no credit.

## Form answers

The value the client actually receives, read from the visit forms. Only visits
that were done, `NOVIS` and `UNKNOWN` are excluded.

| Figure | What it tells the client |
|---|---|
| Facings per answer | Average units of the product on shelf. Shelf presence is the product being sold |
| Training accepted | Share of training actions that ended `OK` |
| Points that order | Share of points of sale that asked to place an order. Commercial intent |

Charts:

- Facings by product. Which products get shelf space and which do not.
- Training results. The distribution behind the single accepted percentage.

All of it reads `mart_visit_responses`, which already carries question,
campaign, point of sale and province on every answer row.

## What is not here

- Percent of plan and pace. The plan figures in the extract are not comparable with these visits, see `notes.md` section 10.
- Campaign state as a column. It has 13 blanks, so `campaign_phase` is derived from the dates instead.
- `expected_answer`. Meaning unknown.

Definitions live in the tooltips of each figure, not in captions, so the screen
stays short.
