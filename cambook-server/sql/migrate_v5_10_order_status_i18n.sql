-- ═══════════════════════════════════════════════════════════════════════════
-- Migration v5.10 — 将订单状态"待接单"更名为"预约订单" + 补全多语言标签
--
-- 实际表名：sys_dict（字段：label_zh / label_en / label_vi / label_km）
-- 影响：
--   sys_dict WHERE dict_type='order_status' AND dict_value='1'
--   label_zh : 待接单  →  预约订单
--   label_en : Waiting →  Appointment
--   label_vi : Chờ    →  Lịch hẹn
--   label_km : រង់ចាំ  →  ការណាត់ជួប
-- ═══════════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;

-- ── 主改动：status 1 重命名 ───────────────────────────────────────────────
UPDATE sys_dict
SET
    label_zh = '预约订单',
    label_en = 'Appointment',
    label_vi = 'Lịch hẹn',
    label_km = 'ការណាត់ជួប'
WHERE dict_type  = 'order_status'
  AND dict_value = '1';

-- ── 补全其余状态的多语言标签（仅填空值，不覆盖已有内容）─────────────────────
UPDATE sys_dict SET label_en = COALESCE(NULLIF(label_en,''), 'Pending Payment'), label_vi = COALESCE(NULLIF(label_vi,''), 'Chờ thanh toán'),  label_km = COALESCE(NULLIF(label_km,''), 'រង់ចាំការទូទាត់')  WHERE dict_type='order_status' AND dict_value='0';
UPDATE sys_dict SET label_en = COALESCE(NULLIF(label_en,''), 'Accepted'),        label_vi = COALESCE(NULLIF(label_vi,''), 'Đã tiếp nhận'),     label_km = COALESCE(NULLIF(label_km,''), 'ទទួលយកហើយ')         WHERE dict_type='order_status' AND dict_value='2';
UPDATE sys_dict SET label_en = COALESCE(NULLIF(label_en,''), 'On The Way'),      label_vi = COALESCE(NULLIF(label_vi,''), 'Đang đến'),          label_km = COALESCE(NULLIF(label_km,''), 'កំពុងធ្វើដំណើរ')     WHERE dict_type='order_status' AND dict_value='3';
UPDATE sys_dict SET label_en = COALESCE(NULLIF(label_en,''), 'Arrived'),         label_vi = COALESCE(NULLIF(label_vi,''), 'Đã đến'),            label_km = COALESCE(NULLIF(label_km,''), 'មកដល់ហើយ')          WHERE dict_type='order_status' AND dict_value='4';
UPDATE sys_dict SET label_en = COALESCE(NULLIF(label_en,''), 'In Service'),      label_vi = COALESCE(NULLIF(label_vi,''), 'Đang phục vụ'),      label_km = COALESCE(NULLIF(label_km,''), 'កំពុងបម្រើ')         WHERE dict_type='order_status' AND dict_value='5';
UPDATE sys_dict SET label_en = COALESCE(NULLIF(label_en,''), 'Completed'),       label_vi = COALESCE(NULLIF(label_vi,''), 'Hoàn thành'),        label_km = COALESCE(NULLIF(label_km,''), 'បានបញ្ចប់')           WHERE dict_type='order_status' AND dict_value='6';
UPDATE sys_dict SET label_en = COALESCE(NULLIF(label_en,''), 'Cancelled'),       label_vi = COALESCE(NULLIF(label_vi,''), 'Đã hủy'),            label_km = COALESCE(NULLIF(label_km,''), 'បានលុបចោល')          WHERE dict_type='order_status' AND dict_value='7';
UPDATE sys_dict SET label_en = COALESCE(NULLIF(label_en,''), 'Refunding'),       label_vi = COALESCE(NULLIF(label_vi,''), 'Đang hoàn tiền'),    label_km = COALESCE(NULLIF(label_km,''), 'កំពុងសង')            WHERE dict_type='order_status' AND dict_value='8';
UPDATE sys_dict SET label_en = COALESCE(NULLIF(label_en,''), 'Refunded'),        label_vi = COALESCE(NULLIF(label_vi,''), 'Đã hoàn tiền'),      label_km = COALESCE(NULLIF(label_km,''), 'បានសងប្រាក់')        WHERE dict_type='order_status' AND dict_value='9';

SELECT CONCAT('已更新 ', ROW_COUNT(), ' 行 order_status 字典数据') AS result;
