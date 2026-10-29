"""Aplica as regras de limpeza documentadas em docs/data_quality_report.md.

Produz, em data/processed/:
    orders_clean.parquet      — 1 linha por pedido entregue, com KPIs derivados
    order_items_clean.parquet — itens com categoria traduzida e receita do pedido
    payments_clean.parquet    — pagamentos dos pedidos válidos

Uso: `python -m src.clean_data`
"""

from pathlib import Path

import pandas as pd

from src.load_data import RAW_DIR, TIMESTAMP_COLUMNS, load_all

PROJECT_ROOT = Path(__file__).resolve().parent.parent
PROCESSED_DIR = PROJECT_ROOT / "data" / "processed"

# Escopo da análise: apenas pedidos concluídos (ver data_quality_report.md #1)
DELIVERED_STATUS = "delivered"


def parse_timestamps(dfs: dict[str, pd.DataFrame]) -> dict[str, pd.DataFrame]:
    """Converte colunas de data para datetime (regra 1)."""
    for name, cols in TIMESTAMP_COLUMNS.items():
        for col in cols:
            dfs[name][col] = pd.to_datetime(dfs[name][col], errors="coerce")
    return dfs


def dedupe_reviews(reviews: pd.DataFrame) -> pd.DataFrame:
    """Mantém apenas a avaliação mais recente de cada pedido (regra 2)."""
    return (
        reviews.sort_values("review_creation_date")
        .drop_duplicates(subset="order_id", keep="last")
        .reset_index(drop=True)
    )


def build_clean_tables(dfs: dict[str, pd.DataFrame]) -> dict[str, pd.DataFrame]:
    """Monta as tabelas limpas com colunas derivadas (regra 4)."""
    orders = dfs["orders"].query("order_status == @DELIVERED_STATUS").copy()
    reviews = dedupe_reviews(dfs["order_reviews"])[["order_id", "review_score"]]

    # Receita e frete agregados por pedido (evita duplicar frete por item)
    order_totals = (
        dfs["order_items"]
        .groupby("order_id")
        .agg(
            order_revenue=("price", "sum"),
            order_freight=("freight_value", "sum"),
        )
        .reset_index()
    )

    orders = (
        orders.merge(order_totals, on="order_id", how="left")
        .merge(reviews, on="order_id", how="left")
        .merge(
            dfs["customers"][["customer_id", "customer_state", "customer_city"]],
            on="customer_id",
            how="left",
        )
    )

    # Colunas derivadas
    orders["order_month"] = orders["order_purchase_timestamp"].dt.to_period("M").astype(str)
    orders["delivery_days"] = (
        orders["order_delivered_customer_date"] - orders["order_purchase_timestamp"]
    ).dt.total_seconds() / 86400
    orders["delivery_delay_days"] = (
        orders["order_delivered_customer_date"] - orders["order_estimated_delivery_date"]
    ).dt.total_seconds() / 86400
    orders["delivered_late"] = orders["delivery_delay_days"] > 0
    orders["freight_ratio"] = orders["order_freight"] / orders["order_revenue"]

    valid_order_ids = set(orders["order_id"])

    items = (
        dfs["order_items"]
        .query("order_id in @valid_order_ids")
        .merge(
            dfs["products"][["product_id", "product_category_name"]],
            on="product_id",
            how="left",
        )
        .merge(
            dfs["translation"],
            on="product_category_name",
            how="left",
        )
        .merge(
            orders[["order_id", "order_revenue"]],
            on="order_id",
            how="left",
        )
    )

    payments = dfs["order_payments"].query("order_id in @valid_order_ids").copy()

    return {
        "orders_clean": orders,
        "order_items_clean": items,
        "payments_clean": payments,
    }


def run(raw_dir: Path = RAW_DIR, processed_dir: Path = PROCESSED_DIR) -> None:
    dfs = parse_timestamps(load_all(raw_dir))
    clean = build_clean_tables(dfs)

    processed_dir.mkdir(parents=True, exist_ok=True)
    for name, df in clean.items():
        path = processed_dir / f"{name}.parquet"
        df.to_parquet(path, index=False)
        print(f"✓ {path.name:<28} {df.shape[0]:>7,} linhas")

    n_late = int(clean["orders_clean"]["delivered_late"].sum())
    print(f"\n{len(clean['orders_clean']):,} pedidos entregues | "
          f"{n_late} com atraso | "
          f"nota média {clean['orders_clean']['review_score'].mean():.2f}")


if __name__ == "__main__":
    run()
