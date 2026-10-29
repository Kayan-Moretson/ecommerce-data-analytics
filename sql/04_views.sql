-- ============================================================
-- 04_views.sql
-- Views analíticas para o dashboard Power BI (PostgreSQL)
-- ============================================================

-- ------------------------------------------------------------
-- Dimensão calendário simples (base para série mensal)
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW dim_calendar AS
SELECT DISTINCT d::date                AS date_day,
               EXTRACT(YEAR  FROM d)   AS year_n,
               EXTRACT(MONTH FROM d)   AS month_n,
               TO_CHAR(d, 'YYYY-MM')   AS year_month
FROM generate_series(
         (SELECT MIN(order_purchase_timestamp)::date FROM orders),
         (SELECT MAX(order_purchase_timestamp)::date FROM orders),
         '1 day'::interval) AS d;

-- ------------------------------------------------------------
-- Fato principal: 1 linha por pedido entregue, com receita,
-- frete, avaliação e atraso — base para quase todo o dashboard
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW fact_orders AS
SELECT
    o.order_id,
    o.order_purchase_timestamp,
    o.order_estimated_delivery_date,
    o.order_delivered_customer_date,
    c.customer_state,
    c.customer_city,
    COALESCE(t.product_category_name_english, p.product_category_name) IS NOT NULL AS has_category,
    SUM(oi.price)                                                AS order_revenue,
    SUM(oi.freight_value)                                        AS order_freight,
    SUM(oi.price + oi.freight_value)                             AS order_total,
    COUNT(DISTINCT oi.seller_id)                                 AS n_sellers,
    COUNT(DISTINCT oi.product_id)                                AS n_products,
    ROUND(SUM(oi.freight_value) / NULLIF(SUM(oi.price), 0), 4)   AS freight_ratio,
    EXTRACT(EPOCH FROM (o.order_delivered_customer_date
                        - o.order_purchase_timestamp)) / 86400   AS delivery_days,
    EXTRACT(EPOCH FROM (o.order_delivered_customer_date
                        - o.order_estimated_delivery_date)) / 86400 AS delivery_delay_days,
    (o.order_delivered_customer_date > o.order_estimated_delivery_date) AS delivered_late,
    r.review_score,
    r.review_comment_message IS NOT NULL                         AS has_comment
FROM orders o
JOIN customers c          ON c.customer_id = o.customer_id
JOIN order_items oi       ON oi.order_id = o.order_id
JOIN products p           ON p.product_id = oi.product_id
LEFT JOIN category_translation t ON t.product_category_name = p.product_category_name
LEFT JOIN LATERAL (
    SELECT review_score, review_comment_message
    FROM order_reviews r
    WHERE r.order_id = o.order_id
    ORDER BY review_creation_date DESC
    LIMIT 1
) r ON true
WHERE o.order_status = 'delivered'
GROUP BY o.order_id, o.order_purchase_timestamp, o.order_estimated_delivery_date,
         o.order_delivered_customer_date, c.customer_state, c.customer_city,
         p.product_category_name, t.product_category_name_english,
         r.review_score, r.review_comment_message;

-- ------------------------------------------------------------
-- KPIs mensais: pedidos, receita, ticket, atraso %, nota média
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_monthly_kpis AS
SELECT TO_CHAR(f.order_purchase_timestamp, 'YYYY-MM') AS year_month,
       COUNT(*)                                       AS orders,
       ROUND(SUM(f.order_revenue), 2)                 AS revenue,
       ROUND(AVG(f.order_revenue), 2)                 AS avg_ticket,
       ROUND(100.0 * SUM(CASE WHEN f.delivered_late
                              THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_late,
       ROUND(AVG(f.delivery_days), 1)                 AS avg_delivery_days,
       ROUND(AVG(f.review_score), 2)                  AS avg_review_score,
       ROUND(100.0 * SUM(CASE WHEN f.review_score = 5 THEN 1 ELSE 0 END) / COUNT(*)
           - 100.0 * SUM(CASE WHEN f.review_score <= 2 THEN 1 ELSE 0 END) / COUNT(*), 1) AS nps
FROM fact_orders f
GROUP BY 1
ORDER BY 1;

-- ------------------------------------------------------------
-- Receita e satisfação por categoria
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_category_performance AS
SELECT COALESCE(t.product_category_name_english, p.product_category_name) AS category,
       COUNT(DISTINCT oi.order_id)                        AS orders,
       ROUND(SUM(oi.price), 2)                            AS revenue,
       ROUND(AVG(oi.price), 2)                            AS avg_item_price,
       ROUND(AVG(r.review_score), 2)                      AS avg_review_score
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
LEFT JOIN category_translation t ON t.product_category_name = p.product_category_name
JOIN order_reviews r ON r.order_id = oi.order_id
GROUP BY 1;

-- ------------------------------------------------------------
-- Desempenho por vendedor (receita, prazo e satisfação)
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_seller_performance AS
SELECT s.seller_id,
       s.seller_state,
       COUNT(DISTINCT oi.order_id)                            AS orders,
       ROUND(SUM(oi.price), 2)                                AS revenue,
       ROUND(AVG(oi.freight_value), 2)                        AS avg_freight,
       ROUND(AVG(EXTRACT(EPOCH FROM (o.order_delivered_carrier_date
                                    - o.order_purchase_timestamp)) / 86400), 1) AS avg_days_to_ship,
       ROUND(AVG(r.review_score), 2)                          AS avg_review_score
FROM sellers s
JOIN order_items oi ON oi.seller_id = s.seller_id
JOIN orders o       ON o.order_id = oi.order_id
LEFT JOIN order_reviews r ON r.order_id = oi.order_id
GROUP BY s.seller_id, s.seller_state;

-- ------------------------------------------------------------
-- Meio de pagamento (para gráficos de composição)
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_payment_mix AS
SELECT TO_CHAR(o.order_purchase_timestamp, 'YYYY-MM') AS year_month,
       pay.payment_type,
       COUNT(DISTINCT pay.order_id)                    AS orders,
       ROUND(SUM(pay.payment_value), 2)                AS total_paid,
       ROUND(AVG(pay.payment_installments), 1)         AS avg_installments
FROM order_payments pay
JOIN orders o ON o.order_id = pay.order_id
GROUP BY 1, 2;
