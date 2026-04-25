-- ═══════════════════════════════════════════════════════════════════════════
-- Migration v5.9 — 補全歷史散客 session 的 service_start_time
--
-- 舊版 startWalkin 接口未寫入 service_start_time。
-- 本腳本對所有 status IN (1,2)（服務中/待結算）且 service_start_time IS NULL
-- 的 session，用 check_in_time 作保底（最差情況是稍微偏大的已服務時間）。
--
-- 執行後重啟後端服務，App 再次進入專注模式即可讀到正確值。
-- ═══════════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;

-- 補全：服務中 / 待結算 且尚無 service_start_time 的 session
UPDATE cb_walkin_session
SET    service_start_time = check_in_time
WHERE  status IN (1, 2)
  AND  service_start_time IS NULL
  AND  deleted = 0;

SELECT CONCAT('已補全 ', ROW_COUNT(), ' 筆歷史 session 的 service_start_time') AS result;
