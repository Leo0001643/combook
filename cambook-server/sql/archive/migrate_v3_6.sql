-- ============================================================
-- v3.6  会员地址字段
-- ============================================================

-- 1. cb_member 新增 address 字段（放在 last_login_ip 之后）
ALTER TABLE cb_member
    ADD COLUMN address VARCHAR(255) NULL COMMENT '会员地址' AFTER last_login_ip;
