-- 1.1. Головний датасет продажів
-- Кожен рядок = одна позиція товару в замовленні
-- позиції доставлених замовлень з контекстом

-- Питання:
-- Які 10 категорій товарів принесли найбільший виторг?

-- Відповідь:
-- 1. health_beauty           — 1,233,131.72
-- 2. watches_gifts           — 1,166,176.98
-- 3. bed_bath_table          — 1,023,434.76
-- 4. sports_leisure          —   954,852.55
-- 5. computers_accessories   —   888,724.61
-- 6. furniture_decor         —   711,927.69
-- 7. housewares              —   615,628.69
-- 8. cool_stuff              —   610,204.10
-- 9. auto                    —   578,966.65
-- 10. toys                   —   471,286.48

-- Логіка:
-- Беремо лише доставлені замовлення, об'єднуємо таблиці
-- товарів, замовлень і категорій, після чого рахуємо
-- сумарний виторг по кожній категорії та сортуємо за спаданням.

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


-- ==========================================
-- 1.2. Місячний підсумок (для прогнозу)
-- ==========================================
-- Формуємо агреговану таблицю по місяцях:
-- • ym      - місяць покупки (YYYY-MM)
-- • revenue - сумарний виторг
-- • orders  - кількість унікальних замовлень

-- Питання:
-- Які штати принесли найбільший виторг?

-- Відповідь:
-- 1. SP — 5,067,633.16 (40,501 замовлення)
-- 2. RJ — 1,759,651.13 (12,350 замовлень)
-- 3. MG — 1,552,481.83 (11,354 замовлення)
-- 4. RS — 728,897.47 (5,345 замовлень)
-- 5. PR — 666,063.51 (4,923 замовлення)
-- 6. SC — 507,012.13 (3,546 замовлень)
-- 7. BA — 493,584.14 (3,256 замовлень)
--
-- Висновок:
-- Найбільший виторг і кількість замовлень припадають на штат SP.
-- Він значно випереджає інші штати, що свідчить про найбільшу концентрацію продажів саме в цьому регіоні.

SELECT
    -- Місяць покупки у форматі YYYY-MM
    strftime('%Y-%m', o.order_purchase_t) AS ym,

    -- Загальний виторг за місяць
    ROUND(SUM(oi.price), 2) AS revenue,

    -- Кількість унікальних замовлень
    COUNT(DISTINCT o.order_id) AS orders

FROM olist_orders_dataset o

-- Приєднуємо товари із замовлень
JOIN olist_order_items_dataset oi
USING (order_id)

-- Беремо лише доставлені замовлення
WHERE o.order_status = 'delivered'

-- Групуємо по місяцях
GROUP BY ym

-- Сортуємо від найстарішого місяця до найновішого
ORDER BY ym;

-- Розвідувальні запити
-- =====================================================
-- 1.3.1. Топ-10 категорій за виторгом
-- =====================================================
-- Логіка:
-- беремо товари із замовлень, приєднуємо замовлення,
-- товари та переклад категорій.
-- Рахуємо суму price по кожній категорії.
-- Залишаємо тільки delivered.

SELECT
    t.product_category_1 AS category_en,          -- категорія англійською
    ROUND(SUM(oi.price), 2) AS revenue,           -- сумарний виторг
    COUNT(DISTINCT o.order_id) AS orders          -- кількість замовлень
FROM olist_order_items_dataset oi
JOIN olist_orders_dataset o USING (order_id)
JOIN olist_products_dataset p USING (product_id)
LEFT JOIN product_category_name_translation t USING (product_category)
WHERE o.order_status = 'delivered'
GROUP BY category_en
ORDER BY revenue DESC
LIMIT 10;

-- =====================================================
-- 1.3.2. Виторг за штатами (для карти Tableau)
-- =====================================================
-- Логіка:
-- 1. Беремо таблицю товарів у замовленнях (order_items),
--    тому що саме тут знаходиться ціна товару.
-- 2. Приєднуємо таблицю замовлень, щоб залишити
--    тільки доставлені замовлення.
-- 3. Приєднуємо таблицю покупців,
--    щоб отримати штат клієнта.
-- 4. Групуємо по штатах.
-- 5. Рахуємо сумарний виторг та кількість замовлень.

SELECT

    cu.customer_state,                          -- штат покупця

    ROUND(SUM(oi.price), 2) AS revenue,         -- сумарний виторг

    COUNT(DISTINCT o.order_id) AS orders        -- кількість замовлень

FROM olist_order_items_dataset oi

JOIN olist_orders_dataset o
USING (order_id)

JOIN olist_customers_dataset cu
USING (customer_id)

WHERE o.order_status = 'delivered'

GROUP BY cu.customer_state

ORDER BY revenue DESC;

-- =====================================================
-- 1.3.3. Середня оцінка (review_score) за категоріями
-- =====================================================
-- Логіка:
-- 1. Починаємо з таблиці відгуків.
-- 2. Приєднуємо товари із замовлення.
-- 3. Приєднуємо таблицю товарів.
-- 4. Приєднуємо переклад категорій.
-- 5. Рахуємо середню оцінку по кожній категорії.
-- 6. Залишаємо лише категорії, де більше 50 відгуків,
--    щоб результат був статистично надійним.

-- Питання:
-- Які категорії товарів мають найвищі оцінки покупців?

-- Відповідь:
-- 1. books_general_interest — 4.45 (549 відгуків)
-- 2. construction_tools_tools — 4.44 (99 відгуків)
-- 3. books_imported — 4.40 (60 відгуків)
-- 4. books_technical — 4.37 (266 відгуків)
-- 5. luggage_accessories — 4.32 (1088 відгуків)
--
-- Висновок:
-- Найвищі середні оцінки отримали книжкові категорії
-- та аксесуари для багажу.

SELECT

    t.product_category_1 AS category_en,      -- категорія англійською

    ROUND(AVG(r.review_score), 2) AS avg_score, -- середня оцінка

    COUNT(*) AS reviews                       -- кількість відгуків

FROM olist_order_reviews_dataset r

JOIN olist_order_items_dataset oi
USING (order_id)

JOIN olist_products_dataset p
USING (product_id)

LEFT JOIN product_category_name_translation t
USING (product_category)

GROUP BY category_en

HAVING reviews > 50

ORDER BY avg_score DESC;

-- =====================================================
-- 1.3.4. Середній час доставки
-- =====================================================
-- Логіка:
-- 1. Беремо таблицю замовлень.
-- 2. Для кожного замовлення рахуємо:
--    дата доставки − дата покупки.
-- 3. julianday() переводить дату у число днів.
-- 4. AVG() знаходить середній час доставки.
-- 5. ROUND(...,1) округляє до одного знака після коми.
-- 6. Беремо тільки доставлені замовлення,
--    у яких відома дата доставки.

-- Питання:
-- Який середній час доставки замовлень?

-- Відповідь:
-- Середній час доставки становить 12.6 днів.
--
-- Висновок:
-- У середньому покупці отримували свої замовлення
-- приблизно через 13 днів після покупки.
SELECT

    ROUND(
        AVG(
            julianday(order_delivered_6)
            - julianday(order_purchase_t)
        ),
        1
    ) AS avg_delivery_days

FROM olist_orders_dataset

WHERE order_status = 'delivered'
  AND order_delivered_6 IS NOT NULL;

-- =====================================================
-- 1.3.5. Розподіл способів оплати
-- =====================================================
-- Логіка:
-- 1. Беремо таблицю оплат.
-- 2. Групуємо записи за способом оплати.
-- 3. Рахуємо кількість оплат кожного типу.
-- 4. Рахуємо загальну суму оплат.
-- 5. Сортуємо від найпоширенішого способу оплати.

-- Питання:
-- Які способи оплати використовувалися найчастіше?

-- Відповідь:
-- 1. credit_card — 76 795 оплат (12 542 084.19)
-- 2. boleto — 19 784 оплат (2 869 361.27)
-- 3. voucher — 5 775 оплат (379 436.87)
-- 4. debit_card — 1 529 оплат (217 989.79)
-- 5. not_defined — 3 оплати (0)
--
-- Висновок:
-- Банківська картка (credit_card) є основним способом
-- оплати, її використовують значно частіше за інші методи.

SELECT

    payment_type,                               -- спосіб оплати

    COUNT(*) AS n,                              -- кількість оплат

    ROUND(SUM(payment_value), 2) AS total_value -- загальна сума оплат

FROM olist_order_payments_dataset

GROUP BY payment_type

ORDER BY n DESC;
