package com.cambook.app.service.merchant.impl;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.cambook.app.common.statemachine.OrderStatus;
import com.cambook.app.common.statemachine.WalkinSessionStatus;
import com.cambook.app.domain.dto.WalkinAddItemDTO;
import com.cambook.app.domain.dto.WalkinCreateDTO;
import com.cambook.app.domain.dto.WalkinSettleDTO;
import com.cambook.app.domain.dto.WalkinUpdateDTO;
import com.cambook.app.domain.vo.WalkinItemVO;
import com.cambook.app.domain.vo.WalkinSessionVO;
import com.cambook.app.service.merchant.IMerchantWalkinService;
import com.cambook.app.websocket.TechWsHandler;
import com.cambook.app.websocket.TechWsRegistry;
import com.cambook.app.websocket.WsMessage;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.PageResult;
import com.cambook.db.entity.CbOrder;
import com.cambook.db.entity.CbServiceCategory;
import com.cambook.db.entity.CbWalkinSession;
import com.cambook.db.service.ICbOrderService;
import com.cambook.db.service.ICbServiceCategoryService;
import com.cambook.db.service.ICbWalkinSessionService;
import com.cambook.common.utils.DateUtils;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;
import java.util.Optional;

/**
 * 商户端散客接待服务实现
 *
 * @author CamBook
 */
@Service
@RequiredArgsConstructor
public class MerchantWalkinServiceImpl implements IMerchantWalkinService {


    private final ICbWalkinSessionService   cbWalkinSessionService;
    private final ICbOrderService           cbOrderService;
    private final ICbServiceCategoryService cbServiceCategoryService;
    private final TechWsRegistry            wsRegistry;
    private final TechWsHandler             wsHandler;
    private final ObjectMapper              objectMapper;

    @Override
    public PageResult<WalkinSessionVO> list(Long merchantId, int page, int size,
                                             String keyword, Integer status, LocalDate date) {
        Page<CbWalkinSession> paged = cbWalkinSessionService.lambdaQuery()
                .eq(CbWalkinSession::getMerchantId, merchantId)
                .eq(status != null, CbWalkinSession::getStatus, status)
                .and(StringUtils.hasText(keyword), q -> q
                        .like(CbWalkinSession::getWristbandNo, keyword).or()
                        .like(CbWalkinSession::getMemberName, keyword).or()
                        .like(CbWalkinSession::getSessionNo, keyword).or()
                        .like(CbWalkinSession::getTechnicianName, keyword))
                .ge(date != null, CbWalkinSession::getCheckInTime, date != null ? date.atStartOfDay() : null)
                .lt(date != null, CbWalkinSession::getCheckInTime, date != null ? date.plusDays(1).atStartOfDay() : null)
                .orderByDesc(CbWalkinSession::getCheckInTime)
                .page(new Page<>(page, size));

        List<Long> sessionIds = paged.getRecords().stream().map(CbWalkinSession::getId).collect(Collectors.toList());
        Map<Long, List<WalkinItemVO>> itemsMap = new HashMap<>();
        if (!sessionIds.isEmpty()) {
            cbOrderService.lambdaQuery()
                    .in(CbOrder::getSessionId, sessionIds).eq(CbOrder::getOrderType, 2)
                    .ne(CbOrder::getStatus, OrderStatus.CANCELLED.getCode())
                    .orderByAsc(CbOrder::getCreateTime).list()
                    .forEach(o -> itemsMap.computeIfAbsent(o.getSessionId(), k -> new ArrayList<>()).add(toItemVO(o)));
        }

        List<WalkinSessionVO> vos = paged.getRecords().stream()
                .map(s -> toSessionVO(s, itemsMap.getOrDefault(s.getId(), Collections.emptyList())))
                .collect(Collectors.toList());
        return PageResult.of(vos, paged.getTotal(), page, size);
    }

    @Override
    public WalkinSessionVO getDetail(Long merchantId, Long sessionId) {
        CbWalkinSession session = requireSession(merchantId, sessionId);
        List<WalkinItemVO> items = listSessionOrders(sessionId).stream()
                .map(this::toItemVO).collect(Collectors.toList());
        return toSessionVO(session, items);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public WalkinSessionVO create(Long merchantId, WalkinCreateDTO dto) {
        CbWalkinSession session = buildSession(merchantId, dto);
        cbWalkinSessionService.save(session);
        pushNewOrderToTech(dto.getTechnicianId(), session.getId());
        return getDetail(merchantId, session.getId());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public WalkinSessionVO createWithItems(Long merchantId, WalkinCreateDTO dto) {
        CbWalkinSession session = buildSession(merchantId, dto);
        cbWalkinSessionService.save(session);

        if (StringUtils.hasText(dto.getItemsJson())) {
            List<Map<String, Object>> items = parseJson(dto.getItemsJson());
            BigDecimal total = BigDecimal.ZERO;
            int idx = 1;
            for (Map<String, Object> item : items) {
                CbOrder order = buildOrderFromItem(session, item, idx++);
                cbOrderService.save(order);
                if (order.getPayAmount() != null) total = total.add(order.getPayAmount());
            }
            session.setTotalAmount(total);
            cbWalkinSessionService.updateById(session);
        }

        pushNewOrderToTech(dto.getTechnicianId(), session.getId());
        return getDetail(merchantId, session.getId());
    }

    @Override
    public void update(Long merchantId, Long sessionId, WalkinUpdateDTO dto) {
        CbWalkinSession session = requireSession(merchantId, sessionId);
        if (dto.getMemberName()       != null) session.setMemberName(dto.getMemberName());
        if (dto.getMemberMobile()     != null) session.setMemberMobile(dto.getMemberMobile());
        if (dto.getTechnicianId()     != null) session.setTechnicianId(dto.getTechnicianId());
        if (dto.getTechnicianName()   != null) session.setTechnicianName(dto.getTechnicianName());
        if (dto.getTechnicianNo()     != null) session.setTechnicianNo(dto.getTechnicianNo());
        if (dto.getTechnicianMobile() != null) session.setTechnicianMobile(dto.getTechnicianMobile());
        if (dto.getRemark()           != null) session.setRemark(dto.getRemark());
        cbWalkinSessionService.updateById(session);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public WalkinItemVO addItem(Long merchantId, Long sessionId, WalkinAddItemDTO dto) {
        CbWalkinSession session = requireSession(merchantId, sessionId);
        if (session.getStatus() >= WalkinSessionStatus.SETTLED.getCode())
            throw new BusinessException(CbCodeEnum.WALKIN_ALREADY_SETTLED);

        int duration = (dto.getServiceDuration() != null && dto.getServiceDuration() > 0)
                ? dto.getServiceDuration() : resolveDuration(dto.getServiceItemId());
        String orderNo = session.getSessionNo() + "-"
                + String.format("%02d", listSessionOrders(sessionId).size() + 1);

        CbOrder order = new CbOrder();
        order.setOrderType((byte)2);             order.setSessionId(sessionId);
        order.setWristbandNo(session.getWristbandNo()); order.setOrderNo(orderNo);
        order.setMerchantId(session.getMerchantId());   order.setMemberId(0L);
        order.setTechnicianId(dto.getTechnicianId() != null ? dto.getTechnicianId() : session.getTechnicianId());
        order.setServiceItemId(dto.getServiceItemId() != null ? dto.getServiceItemId() : 0L);
        order.setServiceName(dto.getServiceName());     order.setServiceDuration(duration);
        order.setAddressId(0L);            order.setAddressDetail("店内服务");
        order.setAppointTime(DateUtils.nowSeconds());
        order.setOriginalAmount(dto.getUnitPrice());    order.setPayAmount(dto.getUnitPrice());
        order.setStatus((byte)OrderStatus.ACCEPTED.getCode());
        cbOrderService.save(order);
        refreshSessionTotal(session);
        return toItemVO(order);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void removeItem(Long merchantId, Long sessionId, Long orderId) {
        CbWalkinSession session = requireSession(merchantId, sessionId);
        CbOrder order = requireOrder(orderId, sessionId);
        if (order.getStatus() == OrderStatus.IN_SERVICE.getCode())
            throw new BusinessException(CbCodeEnum.WALKIN_HAS_ACTIVE_SERVICE);
        cbOrderService.removeById(orderId);
        refreshSessionTotal(session);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateItemPrice(Long merchantId, Long sessionId, Long orderId, BigDecimal unitPrice) {
        CbWalkinSession session = requireSession(merchantId, sessionId);
        CbOrder order = requireOrder(orderId, sessionId);
        if (order.getStatus() == OrderStatus.COMPLETED.getCode())
            throw new BusinessException(CbCodeEnum.ORDER_STATUS_ILLEGAL);
        order.setOriginalAmount(unitPrice);
        order.setPayAmount(unitPrice);
        cbOrderService.updateById(order);
        refreshSessionTotal(session);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void startService(Long merchantId, Long sessionId, Long orderId) {
        CbWalkinSession session = requireSession(merchantId, sessionId);
        CbOrder order = requireOrder(orderId, sessionId);
        if (order.getStatus() != OrderStatus.ACCEPTED.getCode()
                && order.getStatus() != OrderStatus.PENDING_ACCEPT.getCode())
            throw new BusinessException(CbCodeEnum.ORDER_STATUS_ILLEGAL);

        long nowSec = DateUtils.nowSeconds();
        order.setStatus((byte)OrderStatus.IN_SERVICE.getCode());
        order.setStartTime(nowSec);
        cbOrderService.updateById(order);

        if (session.getStatus() == WalkinSessionStatus.CHECKED_IN.getCode()
                || session.getServiceStartTime() == null) {
            session.setStatus((byte)WalkinSessionStatus.IN_SERVICE.getCode());
            session.setServiceStartTime(nowSec);
            cbWalkinSessionService.updateById(session);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void finishService(Long merchantId, Long sessionId, Long orderId) {
        CbWalkinSession session = requireSession(merchantId, sessionId);
        CbOrder order = requireOrder(orderId, sessionId);
        if (order.getStatus() != OrderStatus.IN_SERVICE.getCode())
            throw new BusinessException(CbCodeEnum.ORDER_STATUS_ILLEGAL);

        order.setStatus((byte)OrderStatus.COMPLETED.getCode());
        order.setEndTime(DateUtils.nowSeconds());
        cbOrderService.updateById(order);

        boolean allDone = listSessionOrders(sessionId).stream()
                .allMatch(o -> o.getStatus() == OrderStatus.COMPLETED.getCode());
        if (allDone && session.getStatus() == WalkinSessionStatus.IN_SERVICE.getCode()) {
            session.setStatus((byte)WalkinSessionStatus.SERVICE_DONE.getCode());
            cbWalkinSessionService.updateById(session);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void settle(Long merchantId, Long sessionId, WalkinSettleDTO dto) {
        CbWalkinSession session = requireSession(merchantId, sessionId);
        if (session.getStatus() == WalkinSessionStatus.SETTLED.getCode())
            throw new BusinessException(CbCodeEnum.WALKIN_ALREADY_SETTLED);
        if (session.getStatus() == WalkinSessionStatus.CANCELLED.getCode())
            throw new BusinessException(CbCodeEnum.WALKIN_ALREADY_CANCELLED);

        session.setPaidAmount(dto.getPaidAmount());
        session.setStatus((byte)WalkinSessionStatus.SETTLED.getCode());
        session.setCheckOutTime(DateUtils.nowSeconds());
        if (dto.getRemark() != null) session.setRemark(dto.getRemark());
        cbWalkinSessionService.updateById(session);

        long now = DateUtils.nowSeconds();
        for (CbOrder o : listSessionOrders(sessionId)) {
            if (o.getStatus() == OrderStatus.CANCELLED.getCode()) continue;
            if (o.getStatus() != OrderStatus.COMPLETED.getCode()) { o.setStatus((byte)OrderStatus.COMPLETED.getCode()); o.setEndTime(now); }
            o.setPayTime(now);
            cbOrderService.updateById(o);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void cancel(Long merchantId, Long sessionId, String reason) {
        CbWalkinSession session = requireSession(merchantId, sessionId);
        if (session.getStatus() == WalkinSessionStatus.SETTLED.getCode())
            throw new BusinessException(CbCodeEnum.WALKIN_ALREADY_SETTLED);
        if (session.getStatus() == WalkinSessionStatus.CANCELLED.getCode())
            throw new BusinessException(CbCodeEnum.WALKIN_ALREADY_CANCELLED);

        List<CbOrder> orders = listSessionOrders(sessionId);
        if (orders.stream().anyMatch(o -> o.getStatus() == OrderStatus.IN_SERVICE.getCode()))
            throw new BusinessException(CbCodeEnum.WALKIN_HAS_ACTIVE_SERVICE);

        session.setStatus((byte)WalkinSessionStatus.CANCELLED.getCode());
        session.setRemark(reason != null ? reason : "");
        session.setCheckOutTime(DateUtils.nowSeconds());
        cbWalkinSessionService.updateById(session);

        for (CbOrder o : orders) {
            if (o.getStatus() != OrderStatus.COMPLETED.getCode()) {
                o.setStatus((byte)OrderStatus.CANCELLED.getCode());
                o.setCancelReason(reason != null ? reason : "接待取消");
                cbOrderService.updateById(o);
            }
        }
    }

    // ── 私有辅助 ──────────────────────────────────────────────────────────────

    private CbWalkinSession requireSession(Long merchantId, Long sessionId) {
        CbWalkinSession s = Optional.ofNullable(cbWalkinSessionService.getById(sessionId)).orElseThrow(() -> new BusinessException(CbCodeEnum.WALKIN_NOT_FOUND));
        if (!merchantId.equals(s.getMerchantId())) throw new BusinessException(CbCodeEnum.NO_PERMISSION);
        return s;
    }

    private CbOrder requireOrder(Long orderId, Long sessionId) {
        CbOrder o = cbOrderService.getById(orderId);
        if (o == null || !sessionId.equals(o.getSessionId()))
            throw new BusinessException(CbCodeEnum.WALKIN_ITEM_NOT_FOUND);
        return o;
    }

    private List<CbOrder> listSessionOrders(Long sessionId) {
        return cbOrderService.lambdaQuery().eq(CbOrder::getSessionId, sessionId).eq(CbOrder::getOrderType, 2).orderByAsc(CbOrder::getCreateTime).list();
    }

    private void refreshSessionTotal(CbWalkinSession session) {
        BigDecimal total = listSessionOrders(session.getId()).stream()
                .filter(o -> o.getStatus() != OrderStatus.CANCELLED.getCode())
                .map(CbOrder::getPayAmount).filter(Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        session.setTotalAmount(total);
        cbWalkinSessionService.updateById(session);
    }

    private CbWalkinSession buildSession(Long merchantId, WalkinCreateDTO dto) {
        String sessionNo = "WK" + DateUtils.todayStr("yyyyMMdd")
                + String.format("%03d", (int) (Math.random() * 900 + 100));
        CbWalkinSession s = new CbWalkinSession();
        s.setSessionNo(sessionNo);          s.setWristbandNo(dto.getWristbandNo());
        s.setMerchantId(merchantId);
        s.setMemberName(nvl(dto.getMemberName()));       s.setMemberMobile(nvl(dto.getMemberMobile()));
        s.setTechnicianId(dto.getTechnicianId());
        s.setTechnicianName(nvl(dto.getTechnicianName())); s.setTechnicianNo(nvl(dto.getTechnicianNo()));
        s.setTechnicianMobile(nvl(dto.getTechnicianMobile()));
        s.setStatus((byte)WalkinSessionStatus.CHECKED_IN.getCode());
        s.setTotalAmount(BigDecimal.ZERO);  s.setPaidAmount(BigDecimal.ZERO);
        s.setRemark(nvl(dto.getRemark()));
        s.setCheckInTime(DateUtils.nowSeconds());
        return s;
    }

    private CbOrder buildOrderFromItem(CbWalkinSession session, Map<String, Object> item, int idx) {
        String orderNo = session.getSessionNo() + "-" + String.format("%02d", idx);
        Object priceObj = item.get("unitPrice");
        BigDecimal unitPrice = priceObj == null ? BigDecimal.ZERO
                : (priceObj instanceof BigDecimal bd ? bd : new BigDecimal(priceObj.toString()));
        Object svcIdObj = item.get("serviceItemId");
        long svcId = svcIdObj == null ? 0L : Long.parseLong(svcIdObj.toString());
        Object durObj = item.get("serviceDuration");
        int dur = durObj == null ? 0 : Integer.parseInt(durObj.toString());
        if (dur <= 0 && svcId > 0) dur = resolveDuration(svcId);

        CbOrder order = new CbOrder();
        order.setOrderType((byte)2);             order.setSessionId(session.getId());
        order.setWristbandNo(session.getWristbandNo()); order.setOrderNo(orderNo);
        order.setMerchantId(session.getMerchantId());   order.setMemberId(0L);
        order.setTechnicianId(session.getTechnicianId());
        order.setServiceItemId(svcId);
        order.setServiceName(String.valueOf(item.getOrDefault("serviceName", "")));
        order.setServiceDuration(dur);     order.setAddressId(0L);
        order.setAddressDetail("店内服务");
        order.setAppointTime(DateUtils.nowSeconds());
        order.setOriginalAmount(unitPrice); order.setPayAmount(unitPrice);
        order.setStatus((byte)OrderStatus.ACCEPTED.getCode());
        return order;
    }

    private int resolveDuration(Long serviceItemId) {
        if (serviceItemId == null || serviceItemId <= 0) return 0;
        CbServiceCategory cat = cbServiceCategoryService.getById(serviceItemId);
        return (cat != null && cat.getDuration() != null) ? cat.getDuration() : 0;
    }

    private void pushNewOrderToTech(Long technicianId, Long sessionId) {
        if (technicianId == null) return;
        Runnable push = () -> {
            Map<String, Object> payload = new LinkedHashMap<>();
            payload.put("orderId",   sessionId);
            payload.put("orderType", 2);
            wsRegistry.sendTo(technicianId, WsMessage.newOrder(payload));
            wsHandler.pushHomeData(technicianId);
        };
        if (TransactionSynchronizationManager.isActualTransactionActive()) {
            TransactionSynchronizationManager.registerSynchronization(
                    new TransactionSynchronization() {
                        @Override public void afterCommit() { push.run(); }
                    });
        } else {
            push.run();
        }
    }

    @SuppressWarnings("unchecked")
    private List<Map<String, Object>> parseJson(String json) {
        try {
            return objectMapper.readValue(json,
                    objectMapper.getTypeFactory().constructCollectionType(List.class, Map.class));
        } catch (Exception e) {
            throw new BusinessException(CbCodeEnum.PARAM_ERROR);
        }
    }

    private WalkinSessionVO toSessionVO(CbWalkinSession s, List<WalkinItemVO> items) {
        WalkinSessionVO vo = new WalkinSessionVO();
        vo.setId(s.getId());
        vo.setSessionNo(s.getSessionNo());
        vo.setWristbandNo(s.getWristbandNo());
        vo.setMemberName(s.getMemberName());
        vo.setMemberMobile(s.getMemberMobile());
        vo.setTechnicianId(s.getTechnicianId());
        vo.setTechnicianName(s.getTechnicianName());
        vo.setTechnicianNo(s.getTechnicianNo());
        vo.setTechnicianMobile(s.getTechnicianMobile());
        vo.setStatus(s.getStatus() != null ? s.getStatus().intValue() : null);
        vo.setTotalAmount(s.getTotalAmount());
        vo.setPaidAmount(s.getPaidAmount());
        vo.setCheckInTime(s.getCheckInTime());
        vo.setServiceStartTime(s.getServiceStartTime());
        vo.setCheckOutTime(s.getCheckOutTime());
        vo.setRemark(s.getRemark());
        vo.setOrderItems(items);
        return vo;
    }

    private WalkinItemVO toItemVO(CbOrder o) {
        WalkinItemVO vo = new WalkinItemVO();
        vo.setOrderId(o.getId());    vo.setOrderNo(o.getOrderNo());
        vo.setServiceId(o.getServiceItemId()); vo.setName(o.getServiceName());
        vo.setDuration(o.getServiceDuration() != null ? o.getServiceDuration() : 0);
        vo.setUnitPrice(o.getPayAmount() != null ? o.getPayAmount() : BigDecimal.ZERO);
        vo.setQty(1);
        vo.setSvcStatus(dbStatusToSvcStatus(o.getStatus() != null ? o.getStatus().intValue() : null));
        vo.setStartTime(o.getStartTime()); vo.setEndTime(o.getEndTime());
        vo.setDbStatus(o.getStatus() != null ? o.getStatus().intValue() : 0);
        return vo;
    }

    private static int dbStatusToSvcStatus(Integer dbStatus) {
        if (dbStatus == null) return 0;
        return switch (dbStatus) { case 5 -> 1; case 6 -> 2; default -> 0; };
    }

    private static String nvl(String v) { return v != null ? v : ""; }
}
