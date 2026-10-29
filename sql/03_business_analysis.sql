-- ============================================================
-- 03_business_analysis.sql
-- Análises por hipótese (docs/business_problem.md) — PostgreSQL
-- ============================================================

-- ------------------------------------------------------------
-- KPIs gerais (pedidos entregues como escopo principal)
-- ------------------------------------------------------------
-- 1. Receita total, nº de pedidos, ticket médio, frete médio e nota média
SELECT COUNT(DISTINCT o.order_id)                                   AS pedidos,
       ROUND(SUM(oi.price), 2)                                      AS receita_produtos,
       ROUND(SUM(oi.freight_value), 2)                              AS receita_frete,
       ROUND(SUM(oi.price) / COUNT(DISTINCT o.order_id), 2)         AS ticket_medio,
       ROUND(AVG(r.review_score), 2)                                AS nota_media
FROM orders o
JOIN order_items oi       ON oi.order_id = o.order_id
LEFT JOIN order_reviews r ON r.order_id = o.order_id
WHERE o.order_status = 'delivered';

-- ------------------------------------------------------------
-- H1: atraso na entrega reduz a nota de avaliação
-- ------------------------------------------------------------
-- 2. Nota média por faixa de atraso (dias de atraso = entrega real − estimada)
WITH delivered AS (
    SELECT o.order_id,
           o.order_delivered_customer_date,
           o.order_estimated_delivery_date,
           DATE_PART('day', o.order_delivered_customer_date
                         - o.order_estimated_delivery_date) AS delay_days
    FROM orders o
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
)
SELECT CASE
           WHEN d.delay_days <= -10 THEN '≥10d adiantado'
           WHEN d.delay_days <= -3  THEN '3-9d adiantado'
           WHEN d.delay_days <= 0   THEN 'até 3d adiantado'
           WHEN d.delay_days <= 3   THEN 'até 3d atrasado'
           WHEN d.delay_days <= 10  THEN '4-10d atrasado'
           ELSE '≥10d atrasado'
       END                                AS faixa_atraso,
       COUNT(DISTINCT d.order_id)         AS pedidos,
       ROUND(AVG(r.review_score), 2)      AS nota_media
FROM delivered d
JOIN order_reviews r ON r.order_id = d.order_id
GROUP BY faixa_atraso
ORDER BY MIN(d.delay_days);

-- 3. Tempo médio de entrega por estado do cliente (H3)
SELECT c.customer_state,
       COUNT(DISTINCT o.order_id)                                        AS pedidos,
       ROUND(AVG(EXTRACT(EPOCH FROM (o.order_delivered_customer_date
                                     - o.order_purchase_timestamp)) / 86400), 1) AS dias_entrega_media,
       ROUND(100.0 * SUM(CASE WHEN o.order_delivered_customer_date
                                   > o.order_estimated_delivery_date
                              THEN 1 ELSE 0 END) / COUNT(DISTINCT o.order_id), 1) AS pct_atrasados
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY dias_entrega_media DESC;

-- ------------------------------------------------------------
-- H2: concentração de receita (Pareto por categoria e por vendedor)
-- ------------------------------------------------------------
-- 4. Top 10 categorias por receita e % acumulada
WITH cat_rev AS (
    SELECT COALESCE(t.product_category_name_english, p.product_category_name) AS categoria,
           SUM(oi.price) AS receita
    FROM order_items oi
    JOIN products p ON p.product_id = oi.product_id
    LEFT JOIN category_translation t ON t.product_category_name = p.product_category_name
    GROUP BY 1
), ranked AS (
    SELECT categoria,
           receita,
           SUM(receita) OVER ()                            AS receita_total,
           SUM(receita) OVER (ORDER BY receita DESC)       AS receita_acum
    FROM cat_rev
)
SELECT categoria,
       ROUND(receita, 2)                                            AS receita,
       ROUND(100 * receita / receita_total, 2)                      AS pct_receita,
       ROUND(100 * receita_acum / receita_total, 2)                 AS pct_acumulada
FROM ranked
ORDER BY receita DESC
LIMIT 10;

-- 5. Quantos vendedores concentram 80% da receita
WITH seller_rev AS (
    SELECT seller_id, SUM(price) AS receita
    FROM order_items
    GROUP BY seller_id
), ranked AS (
    SELECT seller_id,
           receita,
           SUM(receita) OVER (ORDER BY receita DESC)  AS receita_acum,
           SUM(receita) OVER ()                       AS receita_total
    FROM seller_rev
)
SELECT COUNT(*)                                        AS vendedores_ate_80pct,
       (SELECT COUNT(*) FROM seller_rev)               AS vendedores_total
FROM ranked
WHERE receita_acum - receita < 0.8 * receita_total;

-- ------------------------------------------------------------
-- H4: meio de pagamento e parcelamento × ticket
-- ------------------------------------------------------------
-- 6. Ticket médio e parcelamento médio por payment_type
SELECT pay.payment_type,
       COUNT(DISTINCT pay.order_id)                     AS pedidos,
       ROUND(SUM(pay.payment_value), 2)                 AS valor_total,
       ROUND(AVG(pay.payment_value), 2)                 AS ticket_medio,
       ROUND(AVG(pay.payment_installments), 1)          AS parcelas_media
FROM order_payments pay
GROUP BY pay.payment_type
ORDER BY valor_total DESC;

-- ------------------------------------------------------------
-- H5: peso do frete no pedido × satisfação
-- ------------------------------------------------------------
-- 7. Nota média por quintil de frete/ preço (freight ratio)
WITH order_freight AS (
    SELECT oi.order_id,
           SUM(oi.freight_value) AS freight,
           SUM(oi.price)         AS price
    FROM order_items oi
    GROUP BY oi.order_id
), scored AS (
    SELECT of_.order_id,
           of_.freight / NULLIF(of_.price, 0) AS freight_ratio,
           r.review_score
    FROM order_freight of_
    JOIN order_reviews r ON r.order_id = of_.order_id
), bucketed AS (
    SELECT *,
           NTILE(5) OVER (ORDER BY freight_ratio) AS quintil_frete
    FROM scored
    WHERE freight_ratio IS NOT NULL
)
SELECT quintil_frete,
       COUNT(*)                         AS pedidos,
       ROUND(MIN(freight_ratio), 3)     AS ratio_min,
       ROUND(MAX(freight_ratio), 3)     AS ratio_max,
       ROUND(AVG(review_score), 2)      AS nota_media
FROM bucketed
GROUP BY quintil_frete
ORDER BY quintil_frete;

-- ------------------------------------------------------------
-- KPI extra: NPS aproximado (promotores 5; detratores 1-2)
-- ------------------------------------------------------------
-- 8. NPS por ano de compra
WITH reviews AS (
    SELECT EXTRACT(YEAR FROM o.order_purchase_timestamp) AS ano,
           r.review_score
    FROM order_reviews r
    JOIN orders o ON o.order_id = r.order_id
)
SELECT ano,
       COUNT(*)                                                            AS avaliacoes,
       ROUND(100.0 * SUM(CASE WHEN review_score = 5 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_promotores,
       ROUND(100.0 * SUM(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_detratores,
       ROUND(100.0 * SUM(CASE WHEN review_score = 5 THEN 1 ELSE 0 END) / COUNT(*)
           - 100.0 * SUM(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END) / COUNT(*), 1) AS nps
FROM reviews
GROUP BY ano
ORDER BY ano;
