"""Testes de qualidade dos dados brutos (data/raw/).

Roda sobre os CSVs originais, sem depender de limpeza prévia —
espelha as verificações de sql/02_quality_checks.sql.

Uso: `pytest tests/ -v`
"""

from pathlib import Path

import pytest

from src.load_data import RAW_DIR, load_all

pytestmark = pytest.mark.skipif(
    not RAW_DIR.exists(), reason="data/raw/ não encontrado"
)


@pytest.fixture(scope="session")
def dfs() -> dict:
    return load_all()


# ------------------------------------------------------------
# Estrutura básica
# ------------------------------------------------------------

def test_todas_as_tabelas_presentes(dfs):
    esperadas = {
        "customers", "geolocation", "orders", "order_items",
        "order_payments", "order_reviews", "products", "sellers", "translation",
    }
    assert esperadas == set(dfs)


def test_sem_linhas_totalmente_duplicadas(dfs):
    for name, df in dfs.items():
        assert df.duplicated().sum() == 0, f"{name}: {df.duplicated().sum()} duplicatas totais"


# ------------------------------------------------------------
# Chaves primárias
# ------------------------------------------------------------

@pytest.mark.parametrize("table, key", [
    ("customers", ["customer_id"]),
    ("orders", ["order_id"]),
    ("order_items", ["order_id", "order_item_id"]),
    ("order_payments", ["order_id", "payment_sequential"]),
    ("products", ["product_id"]),
    ("sellers", ["seller_id"]),
    ("translation", ["product_category_name"]),
])
def test_chaves_unicas(dfs, table, key):
    df = dfs[table]
    assert df.duplicated(subset=key).sum() == 0


# ------------------------------------------------------------
# Integridade referencial
# ------------------------------------------------------------

def test_orders_referenciam_customers(dfs):
    orphans = (~dfs["orders"]["customer_id"].isin(dfs["customers"]["customer_id"])).sum()
    assert orphans == 0


def test_items_referenciam_orders(dfs):
    orphans = (~dfs["order_items"]["order_id"].isin(dfs["orders"]["order_id"])).sum()
    assert orphans == 0


def test_items_referenciam_products(dfs):
    orphans = (~dfs["order_items"]["product_id"].isin(dfs["products"]["product_id"])).sum()
    assert orphans == 0


def test_items_referenciam_sellers(dfs):
    orphans = (~dfs["order_items"]["seller_id"].isin(dfs["sellers"]["seller_id"])).sum()
    assert orphans == 0


def test_payments_referenciam_orders(dfs):
    orphans = (~dfs["order_payments"]["order_id"].isin(dfs["orders"]["order_id"])).sum()
    assert orphans == 0


def test_reviews_referenciam_orders(dfs):
    orphans = (~dfs["order_reviews"]["order_id"].isin(dfs["orders"]["order_id"])).sum()
    assert orphans == 0


# ------------------------------------------------------------
# Domínios e regras de negócio
# ------------------------------------------------------------

def test_review_score_entre_1_e_5(dfs):
    assert dfs["order_reviews"]["review_score"].between(1, 5).all()


def test_status_no_dominio_conhecido(dfs):
    dominio = {
        "delivered", "shipped", "canceled", "unavailable",
        "invoiced", "processing", "created", "approved",
    }
    desconhecidos = set(dfs["orders"]["order_status"].unique()) - dominio
    assert not desconhecidos, f"status fora do domínio: {desconhecidos}"


def test_payment_type_no_dominio_conhecido(dfs):
    dominio = {"credit_card", "boleto", "voucher", "debit_card", "not_defined"}
    desconhecidos = set(dfs["order_payments"]["payment_type"].unique()) - dominio
    assert not desconhecidos, f"payment_type fora do domínio: {desconhecidos}"


def test_precos_e_fretes_nao_negativos(dfs):
    assert (dfs["order_items"]["price"] >= 0).all()
    assert (dfs["order_items"]["freight_value"] >= 0).all()


def test_toda_categoria_de_produto_tem_traducao(dfs):
    sem_traducao = (
        ~dfs["products"]["product_category_name"].dropna()
        .isin(dfs["translation"]["product_category_name"])
    ).sum()
    # Dados conhecidos da Olist: 2 categorias sem tradução — documentado no relatório
    assert sem_traducao <= 2, f"{sem_traducao} categorias sem tradução"


def test_pedidos_entregues_tem_data_de_entrega(dfs):
    entregues = dfs["orders"].query("order_status == 'delivered'")
    sem_data = entregues["order_delivered_customer_date"].isna().sum()
    assert sem_data == 0, f"{sem_data} pedidos entregues sem data de entrega"
