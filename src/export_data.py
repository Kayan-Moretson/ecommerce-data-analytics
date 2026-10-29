"""Exporta as tabelas limpas para formatos consumidos pelo Power BI / SQL.

Gera em data/processed/:
    *.csv  — espelho em CSV das tabelas limpas
    olist_ecommerce.sqlite — banco SQLite com as tabelas limpas

Uso: `python -m src.export_data`
"""

import sqlite3
from pathlib import Path

import pandas as pd

PROJECT_ROOT = Path(__file__).resolve().parent.parent
PROCESSED_DIR = PROJECT_ROOT / "data" / "processed"
SQLITE_PATH = PROCESSED_DIR / "olist_ecommerce.sqlite"

TABLES = ("orders_clean", "order_items_clean", "payments_clean")


def load_processed(processed_dir: Path = PROCESSED_DIR) -> dict[str, pd.DataFrame]:
    """Lê os parquets gerados por src.clean_data."""
    tables = {}
    for name in TABLES:
        path = processed_dir / f"{name}.parquet"
        if not path.exists():
            raise FileNotFoundError(
                f"{path} não encontrado — rode `python -m src.clean_data` primeiro."
            )
        tables[name] = pd.read_parquet(path)
    return tables


def export_csv(tables: dict[str, pd.DataFrame], processed_dir: Path = PROCESSED_DIR) -> None:
    for name, df in tables.items():
        path = processed_dir / f"{name}.csv"
        df.to_csv(path, index=False, encoding="utf-8-sig")
        print(f"✓ {path.name}")


def export_sqlite(tables: dict[str, pd.DataFrame], db_path: Path = SQLITE_PATH) -> None:
    with sqlite3.connect(db_path) as conn:
        for name, df in tables.items():
            df.to_sql(name, conn, if_exists="replace", index=False)
            print(f"✓ sqlite::{name} ({len(df):,} linhas)")


def run() -> None:
    tables = load_processed()
    export_csv(tables)
    export_sqlite(tables)
    print(f"\nExportado para {SQLITE_PATH}")


if __name__ == "__main__":
    run()
