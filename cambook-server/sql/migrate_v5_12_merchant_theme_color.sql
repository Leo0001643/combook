-- migrate_v5_12: 商户 App 主题色字段
-- 为每个商户添加可配置的 App 主题色（pink / ivory 或自定义 hex）
-- 默认值：pink（玫瑰粉）

ALTER TABLE cb_merchant
    ADD COLUMN IF NOT EXISTS theme_color VARCHAR(20) NOT NULL DEFAULT 'pink'
        COMMENT 'App主题色: pink=玫瑰粉, ivory=香槟金, 或自定义 #RRGGBB';
