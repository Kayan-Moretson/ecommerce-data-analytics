# Problema de Negócio

## Pergunta norteadora

> Como uma operação de e-commerce pode melhorar seu desempenho comercial e a
> satisfação dos clientes a partir dos dados de vendas, pagamentos e entregas?

## Contexto

O conjunto de dados (Olist Brazilian E-commerce) representa pedidos reais de um
marketplace brasileiro entre 2016 e 2018: ~100 mil pedidos, com informações de
clientes, produtos, vendedores, pagamentos, avaliações e prazos de entrega.

## Hipóteses a explorar

| # | Hipótese | Métricas-chave |
|---|----------|----------------|
| H1 | O atraso na entrega reduz a nota de avaliação do pedido | dias de atraso vs. `review_score` |
| H2 | Concentramo-nos em poucos vendedores/categorias para a maior parte da receita | participação acumulada (Pareto) |
| H3 | O prazo estimado de entrega é sistematicamente subestimado em certas regiões | `order_estimated_delivery_date` vs. entrega real por estado |
| H4 | O meio de pagamento e o parcelamento influenciam o ticket médio | `payment_type`, `payment_installments` vs. valor do pedido |
| H5 | Frete alto impacta negativamente a conversão/satisfação | `freight_value` / `price` vs. avaliação |

## Métricas de sucesso (KPIs)

- **Receita total e mensal** (soma de `price` por pedido)
- **Ticket médio** (receita / nº de pedidos)
- **Tempo médio de entrega** (compra → entrega ao cliente)
- **% de pedidos entregues com atraso**
- **Nota média de avaliação** (`review_score` 1–5)
- **NPS aproximado** (promotores 5 − detratores 1–2)

## Entregáveis

1. Relatório de qualidade dos dados (`data_quality_report.md`)
2. Análise exploratória (`notebooks/02_exploratory_analysis.ipynb`)
3. Camada analítica em SQL (`sql/03_business_analysis.sql`, `sql/04_views.sql`)
4. Dashboard Power BI (`powerbi/`)
