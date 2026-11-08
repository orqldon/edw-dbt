-- Singular test: a SELECT that returns the rows that break a rule; the test fails
-- if any come back. Use this style for rules the generic tests (unique, not_null,
-- relationships, ...) can't express.
--
-- Rule: an order line's amount is its quantity times its unit price, and is positive.

SELECT
    order_detail_id,
    quantity,
    unit_price,
    line_amount
FROM {{ ref('fct_order_line') }}
WHERE
    quantity <= 0
    OR line_amount <> quantity * unit_price
