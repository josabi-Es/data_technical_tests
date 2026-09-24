# dbt guide

dbt cleans the data and builds the final tables. The data goes through three layers: `raw`, `staging` and `marts`.

## Folders

```
dbt/
├── dbt_project.yml        
├── profiles.yml          
├── macros/
│   ├── clean_string.sql
│   ├── normalize_string.sql
│   └── generate_schema_name.sql
├── models/
│   ├── staging/        
│   └── marts/           
│       ├── dim_pos_unified
│       └── fct_visits
└── tests/          
```

## Problems and solutions

| Problem in the data | Solution | Where |
|---|---|---|
| Airbyte adds metadata columns in `raw` (`_airbyte_*`) | staging picks columns by name, never `select *` | all 7 stg_* |
| Status values with spaces and mixed case (`ok`, `OK `) | trim, upper case, empty to null | stg_visits, stg_routes |
| Names with double spaces and `S.L.` | macros `clean_string` and `normalize_string` | stg_pos_omni, stg_pos_gi |
| Province written in two ways (`PONTEVEDRA`, `Pontevedra`) | upper case | stg_pos_omni, stg_workers |
| 39 stores with one wrong digit in the postal code | second match rule: name, street and number | dim_pos_unified |
| Visits or routes with no status | shown as `UNKNOWN` | fct_visits |

## Macros

| Macro | |
|---|---|
| `clean_string` | basic clean: extra spaces, empty text to null |
| `normalize_string` | lower case, no `S.L.`, to compare names |
| `generate_schema_name` | pick schema staging or marts |


| Original value | After `clean_string` | After `normalize_string` |
|---|---|---|
| `  FarmaVida  Estación 3  S.L. ` | `FarmaVida Estación 3 S.L.` | `farmavida estación 3` |

`clean_string` makes the name clean but keeps it the same. `normalize_string` makes names equal, so we can compare them between omni and gi.

## Marts: the most important part

There are two final tables. With them we can answer the business questions.

**`dim_pos_unified`, the dimension.** One row per real store.
- It joins the two systems (omni and gi) in one table.
- `match_status` says if the store is in both systems (`MATCHED`) or only in one (`OMNI_ONLY`, `GI_ONLY`).
- `match_rule` and `confidence` say how the store was matched.

**`fct_visits`, the fact table.** One row per visit.
- It brings the store, the route, the campaign, the project and the client.
- It is incremental: each load only reads new or changed visits.

What we can get from here:
- visits by store, province, campaign or client
- visits by status (`OK`, `INCID`, `NOVIS`)
- stores that are only in one system

## How to run

In Git Bash:

```
cd data-engineer-test
source .venv/Scripts/activate
uv sync
cd dbt
dbt build
```

The third line loads the `.env` values, because `profiles.yml` reads the Postgres connection from them.

`dbt build` creates the models and runs the tests in order.

## Conclusion

With the two marts we can answer a real business question: how many visits each client and project has, how many were OK, and how many were done at stores that are no longer active.

| client_code | project_name | visits | ok_visits | visits_at_inactive_pos |
|---|---|---|---|---|
| CLI11 | Lanzamiento de Producto Farma | 105 | 91 | 19 |
| CLI05 | Instalación de Expositor Parafarmacia | 78 | 74 | 78 |
| CLI01 | Lanzamiento de Producto Parafarmacia | 75 | 69 | 74 |
| CLI12 | Lanzamiento de Producto Retail | 55 | 48 | 0 |
| CLI01 | Formación de Equipo Parafarmacia | 37 | 29 | 2 |
| CLI05 | Auditoría de Lineal Parafarmacia | 32 | 30 | 0 |
| CLI04 | Control de Stock Salud | 28 | 26 | 0 |
| CLI04 | Lanzamiento de Producto Salud | 20 | 18 | 0 |
| CLI10 | Gestión de Punto de Venta Farma | 19 | 18 | 14 |
| CLI06 | Formación de Equipo Farma | 16 | 6 | 0 |
| CLI12 | Gestión de Punto de Venta Consumo | 15 | 14 | 2 |

