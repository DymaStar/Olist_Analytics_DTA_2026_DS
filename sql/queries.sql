-- 1.1. Головний датасет продажів
-- Кожен рядок = одна позиція товару в замовленні

SELECT
    o.order_id,                              -- ID замовлення
    o.order_purchase_t,                      -- дата і час покупки
    strftime('%Y-%m', o.order_purchase_t) AS ym, -- місяць покупки у форматі РРРР-ММ

    cu.customer_state,                       -- штат покупця

    t.product_category_1 AS category_en,     -- категорія товару англійською

    oi.price,                                -- ціна товару
    oi.freight_value,                        -- вартість доставки

    op.payment_type AS payment_method,       -- спосіб оплати
    r.review_score                           -- оцінка покупця

FROM olist_order_items_dataset oi            -- беремо позиції замовлень

JOIN olist_orders_dataset o
    USING (order_id)                         -- додаємо дату покупки і статус замовлення

JOIN olist_customers_dataset cu
    USING (customer_id)                      -- додаємо штат покупця

JOIN olist_products_dataset p
    USING (product_id)                       -- додаємо категорію товару

JOIN product_category_name_translation t
    USING (product_category)                 -- додаємо переклад категорії

JOIN olist_order_payments_dataset op
    USING (order_id)                         -- додаємо спосіб оплати

JOIN olist_order_reviews_dataset r
    USING (order_id)                         -- додаємо оцінку покупця

WHERE o.order_status = 'delivered';          -- залишаємо тільки доставлені замовлення
