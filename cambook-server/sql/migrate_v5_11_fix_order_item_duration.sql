-- ═══════════════════════════════════════════════════════════════════════════
-- Migration v5.11 — 补全 cb_order_item 中 service_duration = 0 的记录
--
-- 问题：部分在线订单服务项的 service_duration = 0（或 NULL），
--       导致 App 显示"面部护理 · 0分钟"等错误信息。
-- 原因：下单时服务分类未设置 duration，后来在后台补设了值，但历史数据未更新。
-- 修复：从 cb_service_category 中按 service_item_id 回填正确的时长。
-- ═══════════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;

-- 修复在线订单服务项时长
UPDATE cb_order_item oi
    JOIN cb_service_category cat ON cat.id = oi.service_item_id AND cat.deleted = 0
SET oi.service_duration = cat.duration
WHERE (oi.service_duration IS NULL OR oi.service_duration = 0)
  AND oi.service_item_id IS NOT NULL
  AND cat.duration IS NOT NULL
  AND cat.duration > 0
  AND oi.deleted = 0;

SELECT CONCAT('已补全 ', ROW_COUNT(), ' 条在线订单服务项时长') AS result;

-- 修复门店散客订单服务项时长（cb_order order_type=2）
UPDATE cb_order o
    JOIN cb_service_category cat ON cat.id = o.service_item_id AND cat.deleted = 0
SET o.service_duration = cat.duration
WHERE (o.service_duration IS NULL OR o.service_duration = 0)
  AND o.order_type = 2
  AND o.service_item_id IS NOT NULL
  AND cat.duration IS NOT NULL
  AND cat.duration > 0
  AND o.deleted = 0;

SELECT CONCAT('已补全 ', ROW_COUNT(), ' 条门店散客订单服务项时长') AS result;
