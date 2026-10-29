-- ============================================================
-- 02_quality_checks.sql
-- Verificações de qualidade e integridade (PostgreSQL)
-- Cada query retorna uma linha por verificação:
-- check_name | violations | details
-- ============================================================

WITH checks AS (
    -- Chaves primárias duplicadas
    SELECT 'orders.order_id duplicado' AS check_name,
           COUNT(*) - COUNT(DISTINCT order_id) AS violations
    FROM orders

    UNION ALL
    SELECT 'customers.customer_id duplicado',
           COUNT(*) - COUNT(DISTINCT customer_id)
    FROM customers

    UNION ALL
    SELECT 'products.product_id duplicado',
           COUNT(*) - COUNT(DISTINCT product_id)
    FROM products

    UNION ALL
    SELECT 'sellers.seller_id duplicado',
           COUNT(*) - COUNT(DISTINCT seller_id)
    FROM sellers

    -- Integridade referencial (órfãos)
    UNION ALL
    SELECT 'orders sem customer',
           COUNT(*)
    FROM orders o
    LEFT JOIN customers c ON c.customer_id = o.customer_id
    WHERE c.customer_id IS NULL

    UNION ALL
    SELECT 'order_items sem order',
           COUNT(*)
    FROM order_items i
    LEFT JOIN orders o ON o.order_id = i.order_id
    WHERE o.order_id IS NULL

    UNION ALL
    SELECT 'order_items sem product',
           COUNT(*)
    FROM order_items i
    LEFT JOIN products p ON p.product_id = i.product_id
    WHERE p.product_id IS NULL

    UNION ALL
    SELECT 'order_items sem seller',
           COUNT(*)
    FROM order_items i
    LEFT JOIN sellers s ON s.seller_id = i.seller_id
    WHERE s.seller_id IS NULL

    UNION ALL
    SELECT 'pagamentos sem order',
           COUNT(*)
    FROM order_payments pay
    LEFT JOIN orders o ON o.order_id = pay.order_id
    WHERE o.order_id IS NULL

    UNION ALL
    SELECT 'reviews sem order',
           COUNT(*)
    FROM order_reviews r
    LEFT JOIN orders o ON o.order_id = r.order_id
    WHERE o.order_id IS NULL

    -- Categorias sem tradução
    UNION ALL
    SELECT 'categorias sem tradução',
           COUNT(*)
    FROM products p
    LEFT JOIN category_translation t ON t.product_category_name = p.product_category_name
    WHERE p.product_category_name IS NOT NULL
      AND t.product_category_name IS NULL

    -- Domínios
    UNION ALL
    SELECT 'review_score fora de 1-5',
           COUNT(*)
    FROM order_reviews
    WHERE review_score NOT BETWEEN 1 AND 5

    UNION ALL
    SELECT 'price ou freight negativos',
           COUNT(*)
    FROM order_items
    WHERE price < 0 OR freight_value < 0

    UNION ALL
    SELECT 'payment_type fora do domínio',
           COUNT(*)
    FROM order_payments
    WHERE payment_type NOT IN
          ('credit_card', 'boleto', 'voucher', 'debit_card', 'not_defined')

    -- Consistência temporal
    UNION ALL
    SELECT 'entrega antes da compra',
           COUNT(*)
    FROM orders
    WHERE order_delivered_customer_date < order_purchase_timestamp

    UNION ALL
    SELECT 'pedidos entregues sem data de entrega',
           COUNT(*)
    FROM orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NULL

    -- Pagamento × valor dos itens
    UNION ALL
    SELECT 'pedidos: pagamento difere do total de itens (>R$1)',
           COUNT(*)
    FROM (
        SELECT p.order_id, p.paid, it.items_total
        FROM (SELECT order_id, SUM(payment_value) AS paid
              FROM order_payments GROUP BY order_id) p
        JOIN (SELECT order_id, SUM(price + freight_value) AS items_total
              FROM order_items GROUP BY order_id) it USING (order_id)
        WHERE ABS(p.paid - it.items_total) > 1
    ) mismatch
)
SELECT check_name,
       violations,
       CASE WHEN violations = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM checks
ORDER BY status DESC, violations DESC;

-- ------------------------------------------------------------
-- Amostras para inspeção manual
-- ------------------------------------------------------------
-- Pedidos com status entregue mas sem data de entrega:
-- SELECT order_id, order_status, order_purchase_timestamp
-- FROM orders
-- WHERE order_status = 'delivered' AND order_delivered_customer_date IS NULL
-- LIMIT 20;

-- Reviews duplicadas por pedido (mantém a mais recente na limpeza):
-- SELECT order_id, COUNT(*) AS n_reviews
-- FROM order_reviews
-- GROUP BY order_id
-- HAVING COUNT(*) > 1
-- ORDER BY n_reviews DESC
-- LIMIT 20;
