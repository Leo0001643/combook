-- ============================================================
-- v3.7  车辆支持多图
-- ============================================================

-- cb_vehicle：新增多图字段（JSON 数组字符串）
--   原 photo 字段保留，兼容旧数据；photos 存多张图 URL JSON 数组
ALTER TABLE cb_vehicle
    ADD COLUMN photos TEXT NULL COMMENT '车辆多图（JSON数组，如 ["url1","url2"]）' AFTER photo;
