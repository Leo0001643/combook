-- ============================================================
-- Migration v2.3 — 技师表新增身高/体重/年龄/胸围字段
-- ============================================================
ALTER TABLE `cb_technician`
    ADD COLUMN `height`    SMALLINT          NULL COMMENT '身高（cm）'           AFTER `skill_tags`,
    ADD COLUMN `weight`    DECIMAL(5,2)      NULL COMMENT '体重（kg）'           AFTER `height`,
    ADD COLUMN `age`       TINYINT UNSIGNED  NULL COMMENT '年龄'                 AFTER `weight`,
    ADD COLUMN `bust`      VARCHAR(10)       NULL COMMENT '罩杯（A/B/C/D/E/F/G）'       AFTER `age`,
    ADD COLUMN `province`  VARCHAR(50)       NULL COMMENT '所在省份'             AFTER `bust`;
