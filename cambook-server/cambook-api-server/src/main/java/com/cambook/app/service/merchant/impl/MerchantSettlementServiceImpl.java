package com.cambook.app.service.merchant.impl;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.cambook.app.domain.dto.SettlementAdjustDTO;
import com.cambook.app.domain.dto.SettlementBatchPayDTO;
import com.cambook.app.domain.dto.SettlementGenerateDTO;
import com.cambook.app.domain.dto.SettlementPayDTO;
import com.cambook.app.domain.vo.*;
import com.cambook.app.service.merchant.IMerchantSettlementService;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.utils.DateUtils;
import com.cambook.common.exception.BusinessException;
import com.cambook.db.entity.CbTechnicianSettlement;
import com.cambook.db.entity.CbTechnicianSettlementItem;
import com.cambook.db.service.ICbTechnicianSettlementItemService;
import com.cambook.db.service.ICbTechnicianSettlementService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.temporal.WeekFields;
import java.util.*;
import java.util.stream.Collectors;
import java.util.Optional;

/**
 * 商户端技师结算服务实现
 *
 * @author CamBook
 */
@Service
@RequiredArgsConstructor
public class MerchantSettlementServiceImpl implements IMerchantSettlementService {

    private static final int STATUS_PENDING = 0;
    private static final int STATUS_SETTLED = 1;

    private static final String[] DAY_LABELS = {"周一","周二","周三","周四","周五","周六","周日"};

    private final ICbTechnicianSettlementService     cbTechnicianSettlementService;
    private final ICbTechnicianSettlementItemService cbTechnicianSettlementItemService;

    @Override
    public SettlementListVO list(Long merchantId, int page, int size, Long technicianId,
                                  Integer settlementMode, Integer status,
                                  String startDate, String endDate) {
        Page<CbTechnicianSettlement> paged = cbTechnicianSettlementService.lambdaQuery()
                .eq(CbTechnicianSettlement::getMerchantId, merchantId)
                .eq(technicianId   != null, CbTechnicianSettlement::getTechnicianId,   technicianId)
                .eq(settlementMode != null, CbTechnicianSettlement::getSettlementMode, settlementMode)
                .eq(status         != null, CbTechnicianSettlement::getStatus,         status)
                .ge(startDate      != null, CbTechnicianSettlement::getPeriodStart,    startDate)
                .le(endDate        != null, CbTechnicianSettlement::getPeriodEnd,      endDate)
                .orderByDesc(CbTechnicianSettlement::getCreateTime)
                .page(new Page<>(page, size));

        List<CbTechnicianSettlement> all = cbTechnicianSettlementService.lambdaQuery()
                .eq(CbTechnicianSettlement::getMerchantId, merchantId)
                .eq(status != null, CbTechnicianSettlement::getStatus, status).list();

        LocalDate now    = LocalDate.now();
        LocalDate mStart = LocalDate.now().withDayOfMonth(1);
        BigDecimal monthFinal = all.stream()
                .filter(s -> s.getPeriodEnd() != null
                        && !s.getPeriodEnd().isBefore(mStart)
                        && !s.getPeriodEnd().isAfter(now))
                .map(CbTechnicianSettlement::getFinalAmount).filter(Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        SettlementListVO vo = new SettlementListVO();
        vo.setList(paged.getRecords());         vo.setTotal(paged.getTotal());
        vo.setPendingCount(all.stream().filter(s -> s.getStatus() != null && s.getStatus().intValue() == STATUS_PENDING).count());
        vo.setPendingAmount(sumByStatus(all, STATUS_PENDING));
        vo.setSettledAmount(sumByStatus(all, STATUS_SETTLED));
        vo.setMonthAmount(monthFinal);
        return vo;
    }

    @Override
    public SettlementDetailVO detail(Long merchantId, Long id) {
        CbTechnicianSettlement s = requireSettlement(merchantId, id);
        List<CbTechnicianSettlementItem> items = cbTechnicianSettlementItemService.lambdaQuery().eq(CbTechnicianSettlementItem::getSettlementId, id).list();
        SettlementDetailVO vo = new SettlementDetailVO();
        vo.setSettlement(s); vo.setItems(items);
        return vo;
    }

    @Override
    public TechnicianSummaryVO technicianSummary(Long merchantId, Long technicianId) {
        List<CbTechnicianSettlement> list = cbTechnicianSettlementService.lambdaQuery()
                .eq(CbTechnicianSettlement::getMerchantId, merchantId)
                .eq(CbTechnicianSettlement::getTechnicianId, technicianId).list();

        LocalDate mStart = LocalDate.now().withDayOfMonth(1);
        TechnicianSummaryVO vo = new TechnicianSummaryVO();
        vo.setTotalEarnings(list.stream().map(CbTechnicianSettlement::getFinalAmount)
                .filter(Objects::nonNull).reduce(BigDecimal.ZERO, BigDecimal::add));
        vo.setMonthEarnings(list.stream()
                .filter(s -> s.getPeriodEnd() != null && !s.getPeriodEnd().isBefore(mStart))
                .map(CbTechnicianSettlement::getFinalAmount).filter(Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add));
        vo.setPendingCount(list.stream().filter(s -> s.getStatus() != null && s.getStatus().intValue() == STATUS_PENDING).count());
        vo.setPendingAmount(sumByStatus(list, STATUS_PENDING));
        vo.setSettlementCount(list.size());
        return vo;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public CbTechnicianSettlement generate(Long merchantId, SettlementGenerateDTO dto) {
        if (dto.getPeriodStart() != null && dto.getPeriodEnd() != null) {
            long exists = cbTechnicianSettlementService.lambdaQuery()
                    .eq(CbTechnicianSettlement::getMerchantId,   merchantId)
                    .eq(CbTechnicianSettlement::getTechnicianId, dto.getTechnicianId())
                    .eq(CbTechnicianSettlement::getPeriodStart,  LocalDate.parse(dto.getPeriodStart()))
                    .eq(CbTechnicianSettlement::getPeriodEnd,    LocalDate.parse(dto.getPeriodEnd())).count();
            if (exists > 0) throw new BusinessException(CbCodeEnum.SETTLEMENT_PERIOD_EXISTS);
        }

        CbTechnicianSettlement s = new CbTechnicianSettlement();
        s.setMerchantId(merchantId);         s.setTechnicianId(dto.getTechnicianId());
        s.setTechnicianName(dto.getTechnicianName());
        s.setSettlementNo(generateNo());
        s.setSettlementMode(dto.getSettlementMode() != null ? dto.getSettlementMode().byteValue() : (byte)3);
        s.setPeriodStart(dto.getPeriodStart() != null ? LocalDate.parse(dto.getPeriodStart()) : null);
        s.setPeriodEnd(dto.getPeriodEnd() != null ? LocalDate.parse(dto.getPeriodEnd()) : null);
        s.setOrderCount(dto.getOrderCount() != null ? dto.getOrderCount() : 0);
        s.setTotalRevenue(orZero(dto.getTotalRevenue()));
        s.setCommissionType(dto.getCommissionType() != null ? dto.getCommissionType().byteValue() : (byte)0);
        s.setCommissionRate(orZero(dto.getCommissionRate()));
        s.setCommissionAmount(orZero(dto.getCommissionAmount()));
        s.setBonusAmount(orZero(dto.getBonusAmount()));
        s.setDeductionAmount(orZero(dto.getDeductionAmount()));
        s.setCurrencyCode(dto.getCurrencyCode() != null ? dto.getCurrencyCode() : "USD");
        s.setCurrencySymbol(dto.getCurrencySymbol()); s.setRemark(dto.getRemark());
        s.setStatus((byte)STATUS_PENDING);
        s.setFinalAmount(s.getCommissionAmount().add(s.getBonusAmount()).subtract(s.getDeductionAmount()).max(BigDecimal.ZERO));
        cbTechnicianSettlementService.save(s);

        if (dto.getItems() != null) {
            for (SettlementGenerateDTO.Item item : dto.getItems()) {
                CbTechnicianSettlementItem si = new CbTechnicianSettlementItem();
                si.setSettlementId(s.getId());      si.setOrderId(item.getOrderId());
                si.setOrderNo(item.getOrderNo());   si.setServiceName(item.getServiceName());
                si.setOrderAmount(orZero(item.getOrderAmount()));
                si.setCommissionRate(orZero(item.getCommissionRate()));
                si.setCommissionAmount(orZero(item.getCommissionAmount()));
                si.setServiceTime(item.getServiceTime());
                cbTechnicianSettlementItemService.save(si);
            }
        }
        return s;
    }

    @Override
    public void markPaid(Long merchantId, Long id, SettlementPayDTO dto) {
        CbTechnicianSettlement s = requireSettlement(merchantId, id);
        if (s.getStatus() != null && s.getStatus().intValue() == STATUS_SETTLED) throw new BusinessException(CbCodeEnum.SETTLEMENT_ALREADY_PAID);
        s.setStatus((byte)STATUS_SETTLED);
        s.setPaidTime(DateUtils.nowSeconds());
        s.setPaymentMethod(dto.getPaymentMethod()); s.setPaymentRef(dto.getPaymentRef());
        if (dto.getRemark() != null) s.setRemark(dto.getRemark());
        cbTechnicianSettlementService.updateById(s);
    }

    @Override
    public void adjust(Long merchantId, Long id, SettlementAdjustDTO dto) {
        CbTechnicianSettlement s = requireSettlement(merchantId, id);
        if (s.getStatus() != null && s.getStatus().intValue() == STATUS_SETTLED) throw new BusinessException(CbCodeEnum.SETTLEMENT_ALREADY_PAID);
        if (dto.getBonusAmount()     != null) s.setBonusAmount(dto.getBonusAmount());
        if (dto.getDeductionAmount() != null) s.setDeductionAmount(dto.getDeductionAmount());
        if (dto.getRemark()          != null) s.setRemark(dto.getRemark());
        s.setFinalAmount(s.getCommissionAmount().add(s.getBonusAmount()).subtract(s.getDeductionAmount()).max(BigDecimal.ZERO));
        cbTechnicianSettlementService.updateById(s);
    }

    @Override
    public void revoke(Long merchantId, Long id) {
        CbTechnicianSettlement s = requireSettlement(merchantId, id);
        s.setStatus((byte)STATUS_PENDING);
        s.setPaidTime(null);
        cbTechnicianSettlementService.updateById(s);
    }

    @Override
    public void batchPay(Long merchantId, SettlementBatchPayDTO dto) {
        for (Long id : dto.getIds()) {
            CbTechnicianSettlement s = cbTechnicianSettlementService.getById(id);
            if (s == null || !s.getMerchantId().equals(merchantId) || s.getStatus() != null && s.getStatus().intValue() == STATUS_SETTLED) continue;
            s.setStatus((byte)STATUS_SETTLED);
            s.setPaidTime(DateUtils.nowSeconds());
            s.setPaymentMethod(dto.getPaymentMethod()); s.setPaymentRef(dto.getPaymentRef());
            cbTechnicianSettlementService.updateById(s);
        }
    }

    @Override
    public List<SuggestPeriodVO> suggestPeriods(Long technicianId, Integer settlementMode) {
        LocalDate today = LocalDate.now();
        List<SuggestPeriodVO> list = new ArrayList<>();
        switch (settlementMode) {
            case 0 -> list.add(period("当日订单（今天）", today, today, 0));
            case 1 -> { for (int i = 1; i <= 7; i++) { LocalDate d = today.minusDays(i); list.add(period(d + "（" + DAY_LABELS[d.getDayOfWeek().getValue() - 1] + "）", d, d, 1)); } }
            case 2 -> { for (int i = 1; i <= 4; i++) { LocalDate we = today.minusWeeks(i).with(DayOfWeek.SUNDAY); LocalDate ws = we.minusDays(6); list.add(period("第 " + we.get(WeekFields.ISO.weekOfWeekBasedYear()) + " 周（" + ws + " ~ " + we + "）", ws, we, 2)); } }
            case 3 -> { for (int i = 1; i <= 3; i++) { LocalDate m = today.minusMonths(i); LocalDate ms = m.withDayOfMonth(1), me = m.withDayOfMonth(m.lengthOfMonth()); list.add(period(m.getYear() + " 年 " + m.getMonthValue() + " 月", ms, me, 3)); } }
            default -> throw new BusinessException(CbCodeEnum.SETTLEMENT_MODE_INVALID);
        }
        return list;
    }

    // ── 私有辅助 ──────────────────────────────────────────────────────────────

    private CbTechnicianSettlement requireSettlement(Long merchantId, Long id) {
        CbTechnicianSettlement s = Optional.ofNullable(cbTechnicianSettlementService.getById(id)).orElseThrow(() -> new BusinessException(CbCodeEnum.SETTLEMENT_NOT_FOUND));
        if (!s.getMerchantId().equals(merchantId)) throw new BusinessException(CbCodeEnum.NO_PERMISSION);
        return s;
    }

    private BigDecimal sumByStatus(List<CbTechnicianSettlement> list, int status) {
        return list.stream().filter(s -> s.getStatus() != null && s.getStatus().intValue() == status)
                .map(CbTechnicianSettlement::getFinalAmount).filter(Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    private SuggestPeriodVO period(String label, LocalDate start, LocalDate end, int mode) {
        SuggestPeriodVO vo = new SuggestPeriodVO();
        vo.setLabel(label); vo.setStart(start); vo.setEnd(end); vo.setMode(mode);
        return vo;
    }

    private String generateNo() {
        return "SET" + DateUtils.todayStr("yyyyMMdd")
                + (System.currentTimeMillis() % 1_000_000_000L)
                + String.format("%03d", (int) (Math.random() * 1000));
    }

    private BigDecimal orZero(BigDecimal v) { return v != null ? v : BigDecimal.ZERO; }
}
