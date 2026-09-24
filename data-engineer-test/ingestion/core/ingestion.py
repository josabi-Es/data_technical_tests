import csv
import json
import sys
from pathlib import Path

from dotenv import load_dotenv

from utils.postgres import Postgres

DATA_DIR = Path(__file__).parent.parent.parent / "data" / "raw"
COLUMN_MAP = json.loads((Path(__file__).parent / "utils" / "column_map.json").read_text())


def read_csv(csv_path):
    with open(csv_path, encoding="utf-8", newline="") as f:
        reader = csv.reader(f)
        header = next(reader)
        rows = list(reader)
    return header, rows


def load_dataset(db, csv_path):
    dataset = csv_path.stem
    if dataset not in COLUMN_MAP:
        return {"dataset": dataset, "status": "error", "stage": "mapping", "error": "no column mapping defined for this dataset"}

    spec = COLUMN_MAP[dataset]
    expected = spec["columns"]
    for field in ("primary_key", "cursor"):
        if spec[field] is not None and spec[field] not in expected:
            return {"dataset": dataset, "status": "error", "stage": "mapping", "error": f"{field} {spec[field]} is not a column"}

    actual, rows = read_csv(csv_path)
    if actual != expected:
        return {"dataset": dataset, "status": "error", "stage": "validation", "error": f"expected columns {expected}, got {actual}"}

    keys = [row[expected.index(spec["primary_key"])] for row in rows]
    repeated = len(keys) - len(set(keys))
    if repeated:
        return {"dataset": dataset, "status": "error", "stage": "validation", "error": f"primary key {spec['primary_key']} has {repeated} repeated values"}

    try:
        db.create_raw_table(dataset, expected, spec["primary_key"])
        db.load_rows(dataset, expected, rows)
    except Exception as e:
        return {"dataset": dataset, "status": "error", "stage": "load", "error": str(e)}

    return {"dataset": dataset, "status": "ok", "rows": len(rows), "pk_empty": keys.count("")}


def main():
    load_dotenv()
    try:
        db = Postgres()
    except Exception as e:
        print(f"dataset=all stage=connection status=error error={e}")
        sys.exit(1)

    results = [load_dataset(db, f) for f in sorted(DATA_DIR.glob("*.csv"))]
    db.close()

    for r in results:
        print(r)

    if any(r["status"] == "error" for r in results):
        sys.exit(1)


if __name__ == "__main__":
    main()
