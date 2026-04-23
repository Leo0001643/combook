-- ============================================================
-- fix_dict_dedup.sql  安全去重 sys_dict 重复字典数据
--
-- 场景：migrate_v4_6_dict_seed.sql 执行了两次，每个
--       (dict_type, dict_value) 都出现两条完全相同的记录。
--
-- 安全策略：
--   ① 双重条件：id 更大 AND 内容与原始行完全一致，才判定为重复
--      → 手动新增的、内容不同的行绝不会被误删
--   ② 事务保护：DELETE 在事务内执行，确认结果后才 COMMIT，
--      中途任何疑问可立即 ROLLBACK
--   ③ 操作顺序：先看（步骤1）→ 再删（步骤2）→ 再验（步骤3）→ 最后提交
-- ============================================================


-- ════════════════════════════════════════════════════════════
-- 步骤1  预览将被删除的记录（只运行这一段，不要运行下面的事务）
--        结果全部是"内容与某条低 id 行完全相同"的行，核对无误再继续
-- ════════════════════════════════════════════════════════════
SELECT
    dup.id          AS `将删除_id`,
    dup.dict_type,
    dup.dict_value,
    dup.label_zh,
    orig.id         AS `保留的原始_id`
FROM sys_dict AS dup
INNER JOIN sys_dict AS orig
    ON  orig.dict_type  = dup.dict_type
    AND orig.dict_value = dup.dict_value
    AND orig.id         < dup.id          -- orig 是更早插入的那条
    AND orig.label_zh   = dup.label_zh    -- 内容完全相同才视为重复
    AND orig.label_en   = dup.label_en
    AND orig.label_vi   = dup.label_vi
    AND orig.label_km   = dup.label_km
    AND orig.label_ja   = dup.label_ja
    AND orig.label_ko   = dup.label_ko
ORDER BY dup.dict_type, dup.dict_value, dup.id;

-- 预期：查出的每一行都在截图里出现过的高 id 重复记录（如 539-542 等）
-- 若有任何意外行，停止操作，排查原因


-- ════════════════════════════════════════════════════════════
-- 步骤2  在事务内删除（确认步骤1结果无误后再执行）
-- ════════════════════════════════════════════════════════════
START TRANSACTION;

-- 2-A 再次确认：在事务内预览，条数与步骤1一致则继续
SELECT COUNT(*) AS `事务内_待删除数量`
FROM sys_dict AS dup
INNER JOIN sys_dict AS orig
    ON  orig.dict_type  = dup.dict_type
    AND orig.dict_value = dup.dict_value
    AND orig.id         < dup.id
    AND orig.label_zh   = dup.label_zh
    AND orig.label_en   = dup.label_en
    AND orig.label_vi   = dup.label_vi
    AND orig.label_km   = dup.label_km
    AND orig.label_ja   = dup.label_ja
    AND orig.label_ko   = dup.label_ko;

-- 2-B 执行删除（双重条件：id 更大 且 内容完全相同）
DELETE dup
FROM sys_dict AS dup
INNER JOIN sys_dict AS orig
    ON  orig.dict_type  = dup.dict_type
    AND orig.dict_value = dup.dict_value
    AND orig.id         < dup.id
    AND orig.label_zh   = dup.label_zh
    AND orig.label_en   = dup.label_en
    AND orig.label_vi   = dup.label_vi
    AND orig.label_km   = dup.label_km
    AND orig.label_ja   = dup.label_ja
    AND orig.label_ko   = dup.label_ko;

SELECT ROW_COUNT() AS `本次删除行数`;   -- 应与步骤1查出的数量相同


-- ════════════════════════════════════════════════════════════
-- 步骤3  验证（事务内执行，提交前最后确认）
-- ════════════════════════════════════════════════════════════

-- 3-A 应无重复——若有结果则说明还有问题，立即 ROLLBACK
SELECT
    dict_type,
    dict_value,
    COUNT(*) AS cnt
FROM sys_dict
GROUP BY dict_type, dict_value
HAVING cnt > 1
ORDER BY dict_type, dict_value;

-- 3-B 总记录数对比（第一次执行脚本后的正常数量）
SELECT COUNT(*) AS `sys_dict 当前总行数` FROM sys_dict;


-- ════════════════════════════════════════════════════════════
-- 步骤4  根据步骤3的结果二选一
-- ════════════════════════════════════════════════════════════

-- ✅ 步骤3 无重复、总行数正常 → 提交
COMMIT;

-- ❌ 步骤3 有异常 → 回滚，数据完全复原
-- ROLLBACK;


-- ════════════════════════════════════════════════════════════
-- 步骤5（可选）加唯一索引，防止以后再次重复插入
-- ════════════════════════════════════════════════════════════
-- ALTER TABLE sys_dict
--     ADD UNIQUE KEY uk_dict_type_value (dict_type, dict_value);
