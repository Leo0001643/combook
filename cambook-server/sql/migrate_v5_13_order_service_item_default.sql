-- migrate_v5_13: 给 cb_order 所有后台手动建单可能为空的列补充默认值
-- 使用 ALTER COLUMN ... SET DEFAULT，只设默认值，不改类型，不触碰现有数据
-- 避免 MyBatis-Plus 跳过 null 字段时 MySQL 抛出 "doesn't have a default value"

ALTER TABLE cb_order
    ALTER COLUMN service_item_id  SET DEFAULT 0,
    ALTER COLUMN address_id       SET DEFAULT 0,
    ALTER COLUMN address_lat      SET DEFAULT 0,
    ALTER COLUMN address_lng      SET DEFAULT 0,
    ALTER COLUMN start_time       SET DEFAULT 0,
    ALTER COLUMN end_time         SET DEFAULT 0,
    ALTER COLUMN discount_amount  SET DEFAULT 0.00,
    ALTER COLUMN transport_fee    SET DEFAULT 0.00,
    ALTER COLUMN coupon_id        SET DEFAULT 0,
    ALTER COLUMN pay_type         SET DEFAULT 0,
    ALTER COLUMN pay_time         SET DEFAULT 0,
    ALTER COLUMN tech_income      SET DEFAULT 0.00,
    ALTER COLUMN platform_income  SET DEFAULT 0.00,
    ALTER COLUMN is_reviewed      SET DEFAULT 0;
