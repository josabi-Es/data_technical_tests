# Ingestion notes

## Airbyte setup (abctl)

Followed the official quickstart (https://docs.airbyte.com/platform/using-airbyte/getting-started/oss-quickstart):

1. Docker Desktop installed (prerequisite, already had it).
2. `abctl version` to confirm abctl is installed.
3. `abctl local install`
4. Confirm at `http://localhost:8000`.

Destination Postgres created and working: host 192.168.0.14, port 5432, database PrimerImpacto, schema public, SSL disable.

![Postgres destination created in Airbyte](../docs/image/image.png)

## Known issue: sources don't sync live

The CSVs in data/raw could not be linked as a source to the local abctl cluster over HTTPS. `HTTPS: Public Web` rejects the self-signed cert (SSLCertVerificationError, no SSL-verification toggle in the form). `Local Filesystem (limited)` does reach the pod's own filesystem, but populating it needs LOCAL_ROOT/LOCAL_DOCKER_MOUNT/HACK_LOCAL_ROOT_PARENT set in Airbyte's own .env, which only exists for the Docker Compose deployment, not abctl.

So the warehouse is populated instead by a small Python script, ingestion/core/ingestion.py, not a live Airbyte sync. Per-connector JSON config lives in ingestion/sources/ and ingestion/destinations/ (README's actual requirement).

## Fields per source, for reference

Match the values in each ingestion/sources/<source>.yaml:

- Storage Provider: HTTPS
- URL: https://192.168.0.14:8080/<file>.csv
- Dataset Name: same as the file name, e.g. raw_projects
- Format: csv

## Sync mode by connection type

| Fichero | File -> Postgres | Postgres -> Postgres | Primary key | Cursor |
|---|---|---|---|---|
| raw_projects | Full refresh \| Overwrite | Incremental \| Append+Deduped | project_id | updated_at |
| raw_campaigns | Full refresh \| Overwrite | Incremental \| Append+Deduped | campaign_id | updated_at |
| raw_routes | Full refresh \| Overwrite | Full refresh \| Overwrite+Deduped | route_id | none |
| raw_workers | Full refresh \| Overwrite | Full refresh \| Overwrite+Deduped | employee_id | none |
| raw_visits | Full refresh \| Overwrite | Incremental \| Append+Deduped | visit_id | updated_at |
| pos_omni | Full refresh \| Overwrite | Incremental \| Append+Deduped | intervention_point_id | updated_at |
| pos_gi | Full refresh \| Overwrite | Full refresh \| Overwrite+Deduped | ext_id | none |

File -> Postgres: always Full refresh, the File connector just rereads the whole file, no way to filter what changed. (I cant check )

Postgres -> Postgres: can filter, the connector queries the database directly, so Incremental makes sense where there is a cursor. Where there is no updated_at (raw_routes, raw_workers, pos_gi), Full refresh + Deduped with the primary key is the closest option in this UI, real incremental there needs Xmin at the source level, not a per-stream cursor.

### Conclusion

Every source that has an `updated_at` column gets Incremental \| Append+Deduped, with `updated_at` as the cursor. That is the point of a cursor: Airbyte remembers the last value it saw, and next sync only asks the database for rows where `updated_at` is newer than that. If a row did not change, its `updated_at` stays the same, so it is skipped, no need to reread the whole table every time.

The sources without `updated_at` (raw_routes, raw_workers, pos_gi) cannot do this, there is no column to compare against, so they stay Full refresh.

### Test

To check that everything is okay, I run the ingestion process through Python, in /ingestion, where I use libraries like sqlalchemy, dotenv, json, sys. Then, to check that Airbyte works, since I can't access the local filesystem, I check a sync between the same sources like this:

![Airbyte connection test between the same sources](../docs/image/test_conn_Airbytes.png)
