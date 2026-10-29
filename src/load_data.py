"""Carrega os CSVs brutos da Olist em DataFrames pandas.

Uso (na raiz do projeto ou com `python -m src.load_data`):
    from src.load_data import load_all
    dfs = load_all()
"""

from pathlib import Path

import pandas as pd

# Raiz do projeto = dois níveis acima deste arquivo (src/../)
PROJECT_ROOT = Path(__file__).resolve().parent.parent
RAW_DIR = PROJECT_ROOT / "data" / "raw"

FILES = {
    "customers": "olist_customers_dataset.csv",
    "geolocation": "olist_geolocation_dataset.csv",
    "orders": "olist_orders_dataset.csv",
    "order_items": "olist_order_items_dataset.csv",
    "order_payments": "olist_order_payments_dataset.csv",
    "order_reviews": "olist_order_reviews_dataset.csv",
    "products": "olist_products_dataset.csv",
    "sellers": "olist_sellers_dataset.csv",
    "translation": "product_category_name_translation.csv",
}

# Colunas de data por tabela (normalizadas em clean_data)
TIMESTAMP_COLUMNS = {
    "orders": [
        "order_purchase_timestamp",
        "order_approved_at",
        "order_delivered_carrier_date",
        "order_delivered_customer_date",
        "order_estimated_delivery_date",
    ],
    "order_items": ["shipping_limit_date"],
    "order_reviews": ["review_creation_date", "review_answer_timestamp"],
}


def load_table(name: str, data_dir: Path = RAW_DIR) -> pd.DataFrame:
    """Carrega uma tabela bruta pelo nome curto (`orders`, `customers`, ...)."""
    if name not in FILES:
        raise KeyError(f"Tabela desconhecida: {name!r}. Opções: {sorted(FILES)}")
    path = data_dir / FILES[name]
    if not path.exists():
        raise FileNotFoundError(f"Arquivo não encontrado: {path}")
    # utf-8-sig remove o BOM do arquivo de tradução e é inócuo nos demais
    return pd.read_csv(path, encoding="utf-8-sig")


def load_all(data_dir: Path = RAW_DIR) -> dict[str, pd.DataFrame]:
    """Carrega todas as tabelas brutas em um dict {nome: DataFrame}."""
    return {name: load_table(name, data_dir) for name in FILES}


if __name__ == "__main__":
    tables = load_all()
    print(f"{len(tables)} tabelas carregadas de {RAW_DIR}\n")
    for name, df in tables.items():
        print(f"{name:<16} {df.shape[0]:>7,} linhas × {df.shape[1]} colunas")
