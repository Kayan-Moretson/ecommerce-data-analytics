# Relatório de Qualidade dos Dados

> Preenchido a partir de `notebooks/01_data_profiling.ipynb` e validado por
> `tests/test_data_quality.py`. Fonte: `data/raw/`.

## Visão geral

| Arquivo | Linhas | Colunas | Chave(s) | Duplicatas | % Nulos |
|---------|--------|---------|----------|------------|---------|
| olist_customers_dataset.csv | a preencher | 5 | `customer_id` | a preencher | a preencher |
| olist_geolocation_dataset.csv | a preencher | 5 | — | a preencher | a preencher |
| olist_orders_dataset.csv | a preencher | 8 | `order_id` | a preencher | a preencher |
| olist_order_items_dataset.csv | a preencher | 7 | `order_id`+`order_item_id` | a preencher | a preencher |
| olist_order_payments_dataset.csv | a preencher | 5 | `order_id`+`payment_sequential` | a preencher | a preencher |
| olist_order_reviews_dataset.csv | a preencher | 7 | `review_id` | a preencher | a preencher |
| olist_products_dataset.csv | a preencher | 9 | `product_id` | a preencher | a preencher |
| olist_sellers_dataset.csv | a preencher | 4 | `seller_id` | a preencher | a preencher |
| product_category_name_translation.csv | a preencher | 2 | `product_category_name` | a preencher | a preencher |

## Problemas conhecidos e tratamento

| # | Problema | Tabela(s) | Impacto | Tratamento |
|---|----------|-----------|---------|------------|
| 1 | Nulos em datas de entrega/aprovação (pedidos cancelados ou em andamento) | orders | Média de tempo de entrega inflada | Filtrar `order_status = 'delivered'` para métricas de entrega |
| 2 | Comentários de avaliação opcionais (nulos) | reviews | Não afeta nota média | Manter nulos; analisar comentários separadamente |
| 3 | Pedidos com mais de uma avaliação | reviews | Viés se agregar por pedido | Manter avaliação mais recente por pedido |
| 4 | Frete dividido entre itens do mesmo pedido | order_items | Soma simples superestima frete | Somar `freight_value` no nível do pedido |
| 5 | Categorias de produto sem tradução | products / translation | LEFT JOIN perde linhas | Validar cobertura do dicionário de tradução |
| 6 | UTF-8 com BOM no arquivo de tradução | translation | Coluna com nome sujo ao ler | Ler com `encoding='utf-8-sig'` |
| 7 | Pedidos fora do período principal (2016–2018) | orders | Séries mensais com ruído nas pontas | Recortar período de análise |

## Integridade referencial

| Verificação | Resultado |
|-------------|-----------|
| Todo `order.customer_id` existe em customers | a preencher |
| Todo `order_items.product_id` existe em products | a preencher |
| Todo `order_items.seller_id` existe em sellers | a preencher |
| Todo `order_payments.order_id` existe em orders | a preencher |
| Todo `order_reviews.order_id` existe em orders | a preencher |
| Todo `products.product_category_name` tem tradução | a preencher |

## Decisões de limpeza (`src/clean_data.py`)

1. Padronizar timestamps para `datetime`.
2. Remover avaliações duplicadas mantendo a mais recente por pedido.
3. Excluir pedidos de teste/status raros conforme escopo definido na análise.
4. Criar colunas derivadas: `delivery_delay_days`, `order_month`, `freight_ratio`.
