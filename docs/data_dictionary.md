# Dicionário de Dados

Fonte: [Olist Brazilian E-commerce Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) — pedidos de um marketplace brasileiro, 2016–2018.

## Modelo relacional

```
customers ──< orders ──< order_items >── products >── category_translation
                 │  │         └──> sellers
                 │  ├──< order_payments
                 │  └──< order_reviews
                 └──> geolocation (via zip_code_prefix)
```

## olist_customers_dataset.csv

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `customer_id` | texto (PK) | Chave do cliente **por pedido** (cada pedido tem um `customer_id` único) |
| `customer_unique_id` | texto | Identificador único do cliente (permite identificar recorrentes) |
| `customer_zip_code_prefix` | inteiro | Primeiros 5 dígitos do CEP |
| `customer_city` | texto | Cidade do cliente |
| `customer_state` | texto | UF do cliente (2 letras) |

## olist_geolocation_dataset.csv

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `geolocation_zip_code_prefix` | inteiro (FK) | Prefixo de CEP — junta com `*_zip_code_prefix` |
| `geolocation_lat` | decimal | Latitude |
| `geolocation_lng` | decimal | Longitude |
| `geolocation_city` | texto | Cidade |
| `geolocation_state` | texto | UF |

> ⚠️ Um mesmo prefixo de CEP pode ter várias linhas (cada uma com coordenadas).

## olist_orders_dataset.csv

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `order_id` | texto (PK) | Identificador do pedido |
| `customer_id` | texto (FK) | Cliente do pedido → `customers` |
| `order_status` | texto | `delivered`, `shipped`, `canceled`, `unavailable`, `invoiced`, `processing`, `created`, `approved` |
| `order_purchase_timestamp` | datetime | Data/hora da compra |
| `order_approved_at` | datetime | Aprovação do pagamento |
| `order_delivered_carrier_date` | datetime | Postagem na transportadora |
| `order_delivered_customer_date` | datetime | Entrega ao cliente |
| `order_estimated_delivery_date` | date | Prazo de entrega estimado (informado na compra) |

## olist_order_items_dataset.csv

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `order_id` | texto (FK) | Pedido |
| `order_item_id` | inteiro | Número sequencial do item dentro do pedido (PK composta com `order_id`) |
| `product_id` | texto (FK) | Produto → `products` |
| `seller_id` | texto (FK) | Vendedor → `sellers` |
| `shipping_limit_date` | datetime | Prazo limite do vendedor para despachar |
| `price` | decimal | Preço do item (R$) |
| `freight_value` | decimal | Frete do item (R$; pedidos com vários itens podem ter frete dividido) |

## olist_order_payments_dataset.csv

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `order_id` | texto (FK) | Pedido |
| `payment_sequential` | inteiro | Índice do pagamento (pedidos podem ter mais de um) |
| `payment_type` | texto | `credit_card`, `boleto`, `voucher`, `debit_card`, `not_defined` |
| `payment_installments` | inteiro | Nº de parcelas |
| `payment_value` | decimal | Valor da transação (R$) |

## olist_order_reviews_dataset.csv

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `review_id` | texto | Identificador da avaliação |
| `order_id` | texto (FK) | Pedido avaliado |
| `review_score` | inteiro 1–5 | Nota (1 = pior, 5 = melhor) |
| `review_comment_title` | texto | Título do comentário (opcional) |
| `review_comment_message` | texto | Comentário (opcional) |
| `review_creation_date` | datetime | Data da avaliação |
| `review_answer_timestamp` | datetime | Data da resposta |

> ⚠️ Um pedido pode ter mais de uma avaliação (reviews duplicadas por `order_id`).

## olist_products_dataset.csv

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `product_id` | texto (PK) | Identificador do produto |
| `product_category_name` | texto (FK) | Categoria em português → `product_category_name_translation` |
| `product_name_lenght` | decimal | Nº de caracteres do nome |
| `product_description_lenght` | decimal | Nº de caracteres da descrição |
| `product_photos_qty` | decimal | Nº de fotos |
| `product_weight_g` | decimal | Peso (g) |
| `product_length_cm` | decimal | Comprimento (cm) |
| `product_height_cm` | decimal | Altura (cm) |
| `product_width_cm` | decimal | Largura (cm) |

## olist_sellers_dataset.csv

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `seller_id` | texto (PK) | Identificador do vendedor |
| `seller_zip_code_prefix` | inteiro | Prefixo do CEP |
| `seller_city` | texto | Cidade |
| `seller_state` | texto | UF |

## product_category_name_translation.csv

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `product_category_name` | texto (PK) | Categoria em português |
| `product_category_name_english` | texto | Categoria em inglês |

> ⚠️ Arquivo codificado em UTF-8 com BOM.
