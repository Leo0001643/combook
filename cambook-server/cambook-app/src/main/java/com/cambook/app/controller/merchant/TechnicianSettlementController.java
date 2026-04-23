package com.cambook.app.controller.merchant;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.cambook.common.context.MerchantContext;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.Result;
import com.cambook.dao.entity.CbTechnicianSettlement;
import com.cambook.dao.entity.CbTechnicianSettlementItem;
import com.cambook.dao.mapper.CbTechnicianSettlementItemMapper;
import com.cambook.dao.mapper.CbTechnicianSettlementMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.*;
import java.time.format.DateTimeFormatter;
import java.time.temporal.WeekFields;
import java.util.*;
import java.util.stream.Collectors;

/**
 * 商户端 — 技师结算管理
 *
 * <p>支持四种结算模式：
 * <ul>
 *   <li>0 = 每笔结算：手动或自动为单笔订单生成结算</li>
 *   <li>1 = 日结：对某技师某天的订单批量生成结算单</li>
 *   <li>2 = 周结：对某技师某自然周批量生成</li>
 *   <li>3 = 月结：对某技师某自然月批量生成</li>
 * </ul>
 *
 * @author CamBook
 */
@Tag(name = "Merchant - 技师结算")
@RestController
@RequestMapping("/merchant/settlement")
public class TechnicianSettlementController {

    private final CbTechnicianSettlementMapper     settlementMapper;
    private final CbTechnicianSettlementItemMapper itemMapper;

    public TechnicianSettlementController(CbTechnicianSettlementMapper settlementMapper,
                                          CbTechnicianSettlementItemMapper itemMapper) {
        this.settlementMapper = settlementMapper;
        this.itemMapper       = itemMapper;
    }

    // ── 查询接口 ──────────────────────────────────────────────────────────────

    @Operation(summary = "结算列表（分页）")
    @GetMapping("/list")
    public Result<Map<String, Object>> list(
            @RequestParam(defaultValue = "1")  int  page,
            @RequestParam(defaultValue = "20") int  size,
            @RequestParam(required = false)    Long technicianId,
            @RequestParam(required = false)    Integer settlementMode,
            @RequestParam(required = false)    Integer status,
            @RequestParam(required = false) String startDate,
            @RequestParam(required = false) String endDate) {

        Long merchantId = MerchantContext.getMerchantId();

        LambdaQueryWrapper<CbTechnicianSettlement> wrapper = Wrappers.<CbTechnicianSettlement>lambdaQuery()
                .eq(CbTechnicianSettlement::getMerchantId, merchantId)
                .eq(technicianId    != null, CbTechnicianSettlement::getTechnicianId,    technicianId)
                .eq(settlementMode  != null, CbTechnicianSettlement::getSettlementMode,  settlementMode)
                .eq(status          != null, CbTechnicianSettlement::getStatus,          status)
                .ge(startDate       != null, CbTechnicianSettlement::getPeriodStart,     startDate)
                .le(endDate         != null, CbTechnicianSettlement::getPeriodEnd,       endDate)
                .orderByDesc(CbTechnicianSettlement::getCreateTime);

        Page<CbTechnicianSettlement> pageResult =
                settlementMapper.selectPage(new Page<>(page, size), wrapper);

        // 汇总统计（当前商户）
        List<CbTechnicianSettlement> all = settlementMapper.selectList(
                Wrappers.<CbTechnicianSettlement>lambdaQuery()
                        .eq(CbTechnicianSettlement::getMerchantId, merchantId)
                        .eq(status != null, CbTechnicianSettlement::getStatus, status));

        BigDecimal totalPending  = sum(all, 0);
        BigDecimal totalSettled  = sum(all, 1);
        long       pendingCount  = all.stream().filter(s -> s.getStatus() == 0).count();

        // 本月（periodEnd 存储为 YYYY-MM-DD 字符串，字典序等价于日期序）
        String now    = LocalDate.now().toString();
        String mStart = LocalDate.now().withDayOfMonth(1).toString();
        BigDecimal monthFinal = all.stream()
                .filter(s -> s.getPeriodEnd() != null
                        && s.getPeriodEnd().compareTo(mStart) >= 0
                        && s.getPeriodEnd().compareTo(now)    <= 0)
                .map(CbTechnicianSettlement::getFinalAmount)
                .filter(Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("list",         pageResult.getRecords());
        result.put("total",        pageResult.getTotal());
        result.put("pendingCount", pendingCount);
        result.put("pendingAmount",totalPending);
        result.put("settledAmount",totalSettled);
        result.put("monthAmount",  monthFinal);
        return Result.success(result);
    }

    @Operation(summary = "结算单详情")
    @GetMapping("/{id}")
    public Result<Map<String, Object>> detail(@PathVariable Long id) {
        CbTechnicianSettlement s = settlementMapper.selectById(id);
        if (s == null) throw new BusinessException("结算单不存在");
        guardMerchant(s);

        List<CbTechnicianSettlementItem> items = itemMapper.selectList(
                Wrappers.<CbTechnicianSettlementItem>lambdaQuery()
                        .eq(CbTechnicianSettlementItem::getSettlementId, id));

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("settlement", s);
        result.put("items", items);
        return Result.success(result);
    }

    @Operation(summary = "某技师的统计摘要（用于侧边快查）")
    @GetMapping("/summary/{technicianId}")
    public Result<Map<String, Object>> technicianSummary(@PathVariable Long technicianId) {
        Long merchantId = MerchantContext.getMerchantId();

        List<CbTechnicianSettlement> list = settlementMapper.selectList(
                Wrappers.<CbTechnicianSettlement>lambdaQuery()
                        .eq(CbTechnicianSettlement::getMerchantId,   merchantId)
                        .eq(CbTechnicianSettlement::getTechnicianId, technicianId));

        String now    = LocalDate.now().toString();
        String mStart = LocalDate.now().withDayOfMonth(1).toString();

        BigDecimal monthEarnings = list.stream()
                .filter(s -> s.getPeriodEnd() != null && s.getPeriodEnd().compareTo(mStart) >= 0)
                .map(CbTechnicianSettlement::getFinalAmount)
                .filter(Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalEarnings = list.stream()
                .map(CbTechnicianSettlement::getFinalAmount)
                .filter(Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        long pendingCount = list.stream().filter(s -> s.getStatus() == 0).count();
        BigDecimal pendingAmount = sum(list, 0);

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("totalEarnings",  totalEarnings);
        result.put("monthEarnings",  monthEarnings);
        result.put("pendingCount",   pendingCount);
        result.put("pendingAmount",  pendingAmount);
        result.put("settlementCount", list.size());
        return Result.success(result);
    }

    // ── 生成结算单 ────────────────────────────────────────────────────────────

    @Operation(summary = "手动生成结算单")
    @PostMapping("/generate")
    public Result<CbTechnicianSettlement> generate(@RequestBody GenerateRequest req) {
        Long merchantId = MerchantContext.getMerchantId();
        if (req.technicianId == null) throw new BusinessException("技师 ID 不能为空");

        // 检查同周期是否已有结算单（防重复）
        if (req.periodStart != null && req.periodEnd != null) {
            long exists = settlementMapper.selectCount(
                    Wrappers.<CbTechnicianSettlement>lambdaQuery()
                            .eq(CbTechnicianSettlement::getMerchantId,   merchantId)
                            .eq(CbTechnicianSettlement::getTechnicianId, req.technicianId)
                            .eq(CbTechnicianSettlement::getPeriodStart,  req.periodStart)
                            .eq(CbTechnicianSettlement::getPeriodEnd,    req.periodEnd));
            if (exists > 0) throw new BusinessException("该周期已存在结算单，请勿重复生成");
        }

        CbTechnicianSettlement s = new CbTechnicianSettlement();
        s.setMerchantId(merchantId);
        s.setTechnicianId(req.technicianId);
        s.setTechnicianName(req.technicianName);
        s.setSettlementNo(generateNo());
        s.setSettlementMode(req.settlementMode != null ? req.settlementMode : 3);
        s.setPeriodStart(req.periodStart);
        s.setPeriodEnd(req.periodEnd);
        s.setOrderCount(req.orderCount != null ? req.orderCount : 0);
        s.setTotalRevenue(orZero(req.totalRevenue));
        s.setCommissionType(req.commissionType != null ? req.commissionType : 0);
        s.setCommissionRate(orZero(req.commissionRate));
        s.setCommissionAmount(orZero(req.commissionAmount));
        s.setBonusAmount(orZero(req.bonusAmount));
        s.setDeductionAmount(orZero(req.deductionAmount));
        s.setCurrencyCode(req.currencyCode != null ? req.currencyCode : "USD");
        s.setCurrencySymbol(req.currencySymbol);
        s.setRemark(req.remark);
        s.setStatus(0); // 待结算

        // 自动计算最终金额
        BigDecimal finalAmt = s.getCommissionAmount()
                .add(s.getBonusAmount())
                .subtract(s.getDeductionAmount());
        s.setFinalAmount(finalAmt.max(BigDecimal.ZERO));

        settlementMapper.insert(s);

        // 插入明细
        if (req.items != null) {
            for (SettlementItemDTO item : req.items) {
                CbTechnicianSettlementItem si = new CbTechnicianSettlementItem();
                si.setSettlementId(s.getId());
                si.setOrderId(item.orderId);
                si.setOrderNo(item.orderNo);
                si.setServiceName(item.serviceName);
                si.setOrderAmount(orZero(item.orderAmount));
                si.setCommissionRate(orZero(item.commissionRate));
                si.setCommissionAmount(orZero(item.commissionAmount));
                si.setServiceTime(item.serviceTime);
                itemMapper.insert(si);
            }
        }

        return Result.success(s);
    }

    // ── 结算操作 ──────────────────────────────────────────────────────────────

    @Operation(summary = "标记已打款（确认结算）")
    @PatchMapping("/{id}/pay")
    public Result<Void> markPaid(@PathVariable Long id,
                                  @RequestBody PayRequest req) {
        CbTechnicianSettlement s = settlementMapper.selectById(id);
        if (s == null) throw new BusinessException("结算单不存在");
        guardMerchant(s);
        if (s.getStatus() == 1) throw new BusinessException("该结算单已结算，请勿重复操作");

        s.setStatus(1);
        s.setPaidTime(System.currentTimeMillis() / 1000L);
        s.setPaymentMethod(req.paymentMethod);
        s.setPaymentRef(req.paymentRef);
        if (req.remark != null) s.setRemark(req.remark);
        settlementMapper.updateById(s);
        return Result.success();
    }

    @Operation(summary = "调整结算金额（奖励 / 扣款）")
    @PatchMapping("/{id}/adjust")
    public Result<Void> adjust(@PathVariable Long id,
                                @RequestBody AdjustRequest req) {
        CbTechnicianSettlement s = settlementMapper.selectById(id);
        if (s == null) throw new BusinessException("结算单不存在");
        guardMerchant(s);
        if (s.getStatus() == 1) throw new BusinessException("已结算的记录不可调整，请先撤销");

        if (req.bonusAmount    != null) s.setBonusAmount(req.bonusAmount);
        if (req.deductionAmount != null) s.setDeductionAmount(req.deductionAmount);
        if (req.remark         != null) s.setRemark(req.remark);

        BigDecimal finalAmt = s.getCommissionAmount()
                .add(s.getBonusAmount())
                .subtract(s.getDeductionAmount());
        s.setFinalAmount(finalAmt.max(BigDecimal.ZERO));
        settlementMapper.updateById(s);
        return Result.success();
    }

    @Operation(summary = "撤销结算（回退为待结算）")
    @PatchMapping("/{id}/revoke")
    public Result<Void> revoke(@PathVariable Long id) {
        CbTechnicianSettlement s = settlementMapper.selectById(id);
        if (s == null) throw new BusinessException("结算单不存在");
        guardMerchant(s);
        s.setStatus(0);
        s.setPaidTime(null);
        settlementMapper.updateById(s);
        return Result.success();
    }

    @Operation(summary = "批量打款（按 ID 列表）")
    @PostMapping("/batch-pay")
    public Result<Void> batchPay(@RequestBody BatchPayRequest req) {
        if (req.ids == null || req.ids.isEmpty()) throw new BusinessException("ID 列表不能为空");
        Long merchantId = MerchantContext.getMerchantId();

        for (Long id : req.ids) {
            CbTechnicianSettlement s = settlementMapper.selectById(id);
            if (s == null || !s.getMerchantId().equals(merchantId)) continue;
            if (s.getStatus() == 1) continue; // 已结算跳过
            s.setStatus(1);
            s.setPaidTime(System.currentTimeMillis() / 1000L);
            s.setPaymentMethod(req.paymentMethod);
            s.setPaymentRef(req.paymentRef);
            settlementMapper.updateById(s);
        }
        return Result.success();
    }

    // ── 智能生成建议（前端展示待生成周期）────────────────────────────────────

    @Operation(summary = "获取可生成的结算周期建议列表")
    @GetMapping("/suggest-periods")
    public Result<List<Map<String, Object>>> suggestPeriods(
            @RequestParam Long    technicianId,
            @RequestParam Integer settlementMode) {

        List<Map<String, Object>> suggestions = new ArrayList<>();
        LocalDate today = LocalDate.now();

        switch (settlementMode) {
            case 0: // 每笔 — 返回"当日待生成"提示
                Map<String, Object> perOrder = new LinkedHashMap<>();
                perOrder.put("label",  "当日订单（今天）");
                perOrder.put("start",  today);
                perOrder.put("end",    today);
                perOrder.put("mode",   0);
                suggestions.add(perOrder);
                break;

            case 1: // 日结 — 最近 7 天
                for (int i = 1; i <= 7; i++) {
                    LocalDate d = today.minusDays(i);
                    Map<String, Object> day = new LinkedHashMap<>();
                    day.put("label", d.toString() + "（" + dayLabel(d) + "）");
                    day.put("start", d);
                    day.put("end",   d);
                    day.put("mode",  1);
                    suggestions.add(day);
                }
                break;

            case 2: // 周结 — 最近 4 周
                for (int i = 1; i <= 4; i++) {
                    LocalDate weekEnd   = today.minusWeeks(i).with(java.time.DayOfWeek.SUNDAY);
                    LocalDate weekStart = weekEnd.minusDays(6);
                    Map<String, Object> week = new LinkedHashMap<>();
                    week.put("label", "第 " + weekEnd.get(WeekFields.ISO.weekOfWeekBasedYear()) + " 周（" + weekStart + " ~ " + weekEnd + "）");
                    week.put("start", weekStart);
                    week.put("end",   weekEnd);
                    week.put("mode",  2);
                    suggestions.add(week);
                }
                break;

            case 3: // 月结 — 最近 3 个月
                for (int i = 1; i <= 3; i++) {
                    LocalDate m = today.minusMonths(i);
                    LocalDate mStart = m.withDayOfMonth(1);
                    LocalDate mEnd   = m.withDayOfMonth(m.lengthOfMonth());
                    Map<String, Object> month = new LinkedHashMap<>();
                    month.put("label", m.getYear() + " 年 " + m.getMonthValue() + " 月");
                    month.put("start", mStart);
                    month.put("end",   mEnd);
                    month.put("mode",  3);
                    suggestions.add(month);
                }
                break;

            default:
                throw new BusinessException("不支持的结算模式：" + settlementMode);
        }

        return Result.success(suggestions);
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    private void guardMerchant(CbTechnicianSettlement s) {
        if (!s.getMerchantId().equals(MerchantContext.getMerchantId())) {
            throw new BusinessException("无权操作该结算单");
        }
    }

    private BigDecimal sum(List<CbTechnicianSettlement> list, int status) {
        return list.stream()
                .filter(s -> s.getStatus() == status)
                .map(CbTechnicianSettlement::getFinalAmount)
                .filter(Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    private BigDecimal orZero(BigDecimal v) {
        return v != null ? v : BigDecimal.ZERO;
    }

    private String generateNo() {
        return "SET" + LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"))
                + (System.currentTimeMillis() % 1_000_000_000L)
                + String.format("%03d", (int) (Math.random() * 1000));
    }

    private String dayLabel(LocalDate d) {
        java.time.DayOfWeek dow = d.getDayOfWeek();
        String[] LABELS = {"周一","周二","周三","周四","周五","周六","周日"};
        return LABELS[dow.getValue() - 1];
    }

    // ── Request / DTO ────────────────────────────────────────────────────────

    public static class GenerateRequest {
        public Long          technicianId;
        public String        technicianName;
        public Integer       settlementMode;
        public String        periodStart;
        public String        periodEnd;
        public Integer       orderCount;
        public BigDecimal    totalRevenue;
        public Integer       commissionType;
        public BigDecimal    commissionRate;
        public BigDecimal    commissionAmount;
        public BigDecimal    bonusAmount;
        public BigDecimal    deductionAmount;
        public String        currencyCode;
        public String        currencySymbol;
        public String        remark;
        public List<SettlementItemDTO> items;
    }

    public static class SettlementItemDTO {
        public Long          orderId;
        public String        orderNo;
        public String        serviceName;
        public BigDecimal    orderAmount;
        public BigDecimal    commissionRate;
        public BigDecimal    commissionAmount;
        public Long          serviceTime;
    }

    public static class PayRequest {
        public String paymentMethod;
        public String paymentRef;
        public String remark;
    }

    public static class AdjustRequest {
        public BigDecimal bonusAmount;
        public BigDecimal deductionAmount;
        public String     remark;
    }

    public static class BatchPayRequest {
        public List<Long> ids;
        public String     paymentMethod;
        public String     paymentRef;
    }
}
