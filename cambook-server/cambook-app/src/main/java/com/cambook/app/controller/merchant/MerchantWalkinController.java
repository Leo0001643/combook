package com.cambook.app.controller.merchant;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.cambook.common.context.MerchantContext;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.Result;
import com.cambook.dao.entity.CbOrder;
import com.cambook.dao.entity.CbWalkinSession;
import com.cambook.dao.mapper.CbOrderMapper;
import com.cambook.dao.mapper.CbWalkinSessionMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;
/**
 * 商户端 — 散客接待管理（Walk-in Session）
 *
 * <p>数据闭环：
 * <pre>
 * cb_walkin_session（接待主记录）
 *     └── cb_order（order_type=2, session_id=主记录ID）（每项服务为一条订单）
 *             ├── start_time  → 前端 svcStatus=1 (服务中) 的进度来源
 *             ├── end_time    → 服务完成时间
 *             ├── service_duration → 时长（分钟），进度条最大值
 *             └── status: 1/2=待服务(svcStatus=0) 5=服务中(svcStatus=1) 6=已完成(svcStatus=2)
 * </pre>
 *
 * @author CamBook
 */
@Tag(name = "商户端 - 散客接待管理")
@RestController
@RequestMapping("/merchant/walkin")
public class MerchantWalkinController {

    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("yyyyMMdd");

    /**
     * 前端 svcStatus → 数据库 cb_order.status 映射
     *   svcStatus 0 (待服务) → status IN (1, 2)
     *   svcStatus 1 (服务中) → status = 5
     *   svcStatus 2 (已完成) → status = 6
     */
    private static int dbStatusToSvcStatus(Integer dbStatus) {
        if (dbStatus == null) return 0;
        return switch (dbStatus) {
            case 5  -> 1;   // 服务中
            case 6  -> 2;   // 已完成
            default -> 0;   // 待服务（包含 1=待接单, 2=已确认）
        };
    }

    private final CbWalkinSessionMapper sessionMapper;
    private final CbOrderMapper         orderMapper;

    public MerchantWalkinController(CbWalkinSessionMapper sessionMapper,
                                    CbOrderMapper orderMapper) {
        this.sessionMapper = sessionMapper;
        this.orderMapper   = orderMapper;
    }

    // ── 1. Session 列表（分页 + 过滤）────────────────────────────────────────────

    @Operation(summary = "散客接待列表（分页）")
    @GetMapping("/list")
    public Result<Map<String, Object>> list(
            @RequestParam(defaultValue = "1")  int     page,
            @RequestParam(defaultValue = "20") int     size,
            @RequestParam(required = false)    String  keyword,
            @RequestParam(required = false)    Integer status,
            @RequestParam(required = false)    @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate date) {

        Long merchantId = MerchantContext.getMerchantId();

        LambdaQueryWrapper<CbWalkinSession> wrapper = Wrappers.<CbWalkinSession>lambdaQuery()
                .eq(CbWalkinSession::getMerchantId, merchantId)
                .eq(status != null, CbWalkinSession::getStatus, status)
                .and(StringUtils.hasText(keyword), q -> q
                        .like(CbWalkinSession::getWristbandNo, keyword)
                        .or().like(CbWalkinSession::getMemberName, keyword)
                        .or().like(CbWalkinSession::getSessionNo, keyword)
                        .or().like(CbWalkinSession::getTechnicianName, keyword))
                .ge(date != null, CbWalkinSession::getCheckInTime, date != null ? date.atStartOfDay() : null)
                .lt(date != null, CbWalkinSession::getCheckInTime, date != null ? date.plusDays(1).atStartOfDay() : null)
                .orderByDesc(CbWalkinSession::getCheckInTime);

        Page<CbWalkinSession> pageResult = sessionMapper.selectPage(new Page<>(page, size), wrapper);

        // 批量查询每个 session 的服务项（避免 N+1）
        List<Long> sessionIds = pageResult.getRecords().stream()
                .map(CbWalkinSession::getId).collect(Collectors.toList());

        Map<Long, List<Map<String, Object>>> itemsMap = new HashMap<>();
        if (!sessionIds.isEmpty()) {
            List<CbOrder> orders = orderMapper.selectList(
                    Wrappers.<CbOrder>lambdaQuery()
                            .in(CbOrder::getSessionId, sessionIds)
                            .eq(CbOrder::getOrderType, 2)
                            .ne(CbOrder::getStatus, 7)  // 排除已取消
                            .orderByAsc(CbOrder::getCreateTime));
            orders.forEach(o -> itemsMap
                    .computeIfAbsent(o.getSessionId(), k -> new ArrayList<>())
                    .add(orderToItemVO(o)));
        }

        List<Map<String, Object>> records = pageResult.getRecords().stream()
                .map(s -> sessionToVO(s, itemsMap.getOrDefault(s.getId(), Collections.emptyList())))
                .collect(Collectors.toList());

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("total",   pageResult.getTotal());
        result.put("page",    page);
        result.put("size",    size);
        result.put("list",    records);
        return Result.success(result);
    }

    // ── 2. Session 详情 ───────────────────────────────────────────────────────────

    @Operation(summary = "散客接待详情（含服务项列表）")
    @GetMapping("/{id}")
    public Result<Map<String, Object>> detail(@PathVariable Long id) {
        CbWalkinSession session = requireSession(id);
        List<CbOrder> orders = listSessionOrders(id);
        List<Map<String, Object>> items = orders.stream().map(this::orderToItemVO).collect(Collectors.toList());
        return Result.success(sessionToVO(session, items));
    }

    // ── 3. 新增接待（仅 session，不含服务项） ─────────────────────────────────────

    @Operation(summary = "新增散客接待")
    @PostMapping("/create")
    public Result<Map<String, Object>> create(
            @RequestParam String  wristbandNo,
            @RequestParam(required = false) String  memberName,
            @RequestParam(required = false) String  memberMobile,
            @RequestParam(required = false) Long    technicianId,
            @RequestParam(required = false) String  technicianName,
            @RequestParam(required = false) String  technicianNo,
            @RequestParam(required = false) String  technicianMobile,
            @RequestParam(required = false) String  remark) {

        Long merchantId = MerchantContext.getMerchantId();

        // 同一商户当天手环编号不重复
        long conflict = sessionMapper.selectCount(Wrappers.<CbWalkinSession>lambdaQuery()
                .eq(CbWalkinSession::getMerchantId, merchantId)
                .eq(CbWalkinSession::getWristbandNo, wristbandNo)
                .ge(CbWalkinSession::getCheckInTime, LocalDate.now().atStartOfDay())
                .notIn(CbWalkinSession::getStatus, 3, 4));  // 排除已结算/已取消
        if (conflict > 0) throw new BusinessException("手环编号 " + wristbandNo + " 今日已被使用");

        String sessionNo = "WK" + LocalDate.now().format(DATE_FMT)
                + String.format("%03d", (int)(Math.random() * 900 + 100));

        CbWalkinSession session = new CbWalkinSession();
        session.setSessionNo(sessionNo);
        session.setWristbandNo(wristbandNo);
        session.setMerchantId(merchantId);
        session.setMemberName(memberName != null ? memberName : "");
        session.setMemberMobile(memberMobile != null ? memberMobile : "");
        session.setTechnicianId(technicianId);
        session.setTechnicianName(technicianName != null ? technicianName : "");
        session.setTechnicianNo(technicianNo != null ? technicianNo : "");
        session.setTechnicianMobile(technicianMobile != null ? technicianMobile : "");
        session.setStatus(0);
        session.setTotalAmount(BigDecimal.ZERO);
        session.setPaidAmount(BigDecimal.ZERO);
        session.setRemark(remark != null ? remark : "");
        session.setCheckInTime(LocalDateTime.now());
        sessionMapper.insert(session);

        return detail(session.getId());
    }

    // ── 3b. 新增接待（含服务项，事务保证原子性）────────────────────────────────────

    @Operation(summary = "新增散客接待（含服务项，原子操作）")
    @PostMapping("/createWithItems")
    @Transactional(rollbackFor = Exception.class)
    public Result<Map<String, Object>> createWithItems(
            @RequestParam String  wristbandNo,
            @RequestParam(required = false) String  memberName,
            @RequestParam(required = false) String  memberMobile,
            @RequestParam(required = false) Long    technicianId,
            @RequestParam(required = false) String  technicianName,
            @RequestParam(required = false) String  technicianNo,
            @RequestParam(required = false) String  technicianMobile,
            @RequestParam(required = false) String  remark,
            // 服务项列表（JSON 字符串，格式：[{"serviceItemId":1,"serviceName":"...","serviceDuration":60,"unitPrice":288}]）
            @RequestParam(required = false) String  itemsJson) {

        Long merchantId = MerchantContext.getMerchantId();

        // 同一商户当天手环编号不重复
        long conflict = sessionMapper.selectCount(Wrappers.<CbWalkinSession>lambdaQuery()
                .eq(CbWalkinSession::getMerchantId, merchantId)
                .eq(CbWalkinSession::getWristbandNo, wristbandNo)
                .ge(CbWalkinSession::getCheckInTime, LocalDate.now().atStartOfDay())
                .notIn(CbWalkinSession::getStatus, 3, 4));
        if (conflict > 0) throw new BusinessException("手环编号 " + wristbandNo + " 今日已被使用");

        String sessionNo = "WK" + LocalDate.now().format(DATE_FMT)
                + String.format("%03d", (int)(Math.random() * 900 + 100));

        CbWalkinSession session = new CbWalkinSession();
        session.setSessionNo(sessionNo);
        session.setWristbandNo(wristbandNo);
        session.setMerchantId(merchantId);
        session.setMemberName(memberName != null ? memberName : "");
        session.setMemberMobile(memberMobile != null ? memberMobile : "");
        session.setTechnicianId(technicianId);
        session.setTechnicianName(technicianName != null ? technicianName : "");
        session.setTechnicianNo(technicianNo != null ? technicianNo : "");
        session.setTechnicianMobile(technicianMobile != null ? technicianMobile : "");
        session.setStatus(0);
        session.setTotalAmount(BigDecimal.ZERO);
        session.setPaidAmount(BigDecimal.ZERO);
        session.setRemark(remark != null ? remark : "");
        session.setCheckInTime(LocalDateTime.now());
        sessionMapper.insert(session);   // ← 若后续步骤抛异常，此 INSERT 一并回滚

        // 解析并插入服务项
        if (StringUtils.hasText(itemsJson)) {
            List<Map<String, Object>> items = parseItemsJson(itemsJson);
            BigDecimal totalAmount = BigDecimal.ZERO;
            int idx = 1;
            for (Map<String, Object> item : items) {
                CbOrder order = buildOrderFromItem(session, item, idx++);
                orderMapper.insert(order);   // ← 任何一条失败，整个事务回滚
                if (order.getPayAmount() != null) totalAmount = totalAmount.add(order.getPayAmount());
            }
            session.setTotalAmount(totalAmount);
            sessionMapper.updateById(session);
        }

        return detail(session.getId());
    }

    // ── 4. 修改接待信息 ───────────────────────────────────────────────────────────

    @Operation(summary = "修改散客接待基本信息")
    @PostMapping("/{id}/update")
    public Result<Void> update(
            @PathVariable Long id,
            @RequestParam(required = false) String memberName,
            @RequestParam(required = false) String memberMobile,
            @RequestParam(required = false) Long   technicianId,
            @RequestParam(required = false) String technicianName,
            @RequestParam(required = false) String technicianNo,
            @RequestParam(required = false) String technicianMobile,
            @RequestParam(required = false) String remark) {

        CbWalkinSession session = requireSession(id);
        if (memberName    != null) session.setMemberName(memberName);
        if (memberMobile  != null) session.setMemberMobile(memberMobile);
        if (technicianId  != null) { session.setTechnicianId(technicianId); }
        if (technicianName  != null) session.setTechnicianName(technicianName);
        if (technicianNo    != null) session.setTechnicianNo(technicianNo);
        if (technicianMobile != null) session.setTechnicianMobile(technicianMobile);
        if (remark        != null) session.setRemark(remark);
        sessionMapper.updateById(session);
        return Result.success();
    }

    // ── 5. 添加服务项 ──────────────────────────────────────────────────────────────

    @Operation(summary = "添加服务项（到 session）")
    @PostMapping("/{id}/addItem")
    @Transactional(rollbackFor = Exception.class)
    public Result<Map<String, Object>> addItem(
            @PathVariable Long id,
            @RequestParam Long    serviceItemId,
            @RequestParam String  serviceName,
            @RequestParam Integer serviceDuration,
            @RequestParam BigDecimal unitPrice) {

        CbWalkinSession session = requireSession(id);
        if (session.getStatus() >= 3) throw new BusinessException("当前接待已结算或已取消，无法新增服务项");

        String orderNo = session.getSessionNo() + "-"
                + String.format("%02d", listSessionOrders(id).size() + 1);

        CbOrder order = new CbOrder();
        order.setOrderType(2);
        order.setSessionId(id);
        order.setWristbandNo(session.getWristbandNo());
        order.setOrderNo(orderNo);
        order.setMerchantId(session.getMerchantId());
        order.setMemberId(0L);             // 散客不关联会员账号，设为 0 满足 NOT NULL 约束
        order.setTechnicianId(session.getTechnicianId());
        order.setServiceItemId(serviceItemId);
        order.setServiceName(serviceName);
        order.setServiceDuration(serviceDuration);
        order.setAddressId(0L);
        order.setAddressDetail("店内服务");
        order.setAppointTime(LocalDateTime.now());
        order.setOriginalAmount(unitPrice);
        order.setPayAmount(unitPrice);
        order.setStatus(2);   // 已确认，待服务
        orderMapper.insert(order);

        refreshSessionTotal(session);
        return Result.success(orderToItemVO(order));
    }

    // ── 6. 删除服务项 ──────────────────────────────────────────────────────────────

    @Operation(summary = "删除服务项")
    @DeleteMapping("/{id}/items/{orderId}")
    public Result<Void> removeItem(@PathVariable Long id, @PathVariable Long orderId) {
        CbWalkinSession session = requireSession(id);
        CbOrder order = requireOrder(orderId, id);
        if (order.getStatus() == 5) throw new BusinessException("服务进行中，无法删除");
        orderMapper.deleteById(orderId);
        refreshSessionTotal(session);
        return Result.success();
    }

    // ── 7. 修改服务项单价 ─────────────────────────────────────────────────────────

    @Operation(summary = "修改服务项单价")
    @PostMapping("/{id}/items/{orderId}/price")
    public Result<Void> updateItemPrice(
            @PathVariable Long id, @PathVariable Long orderId,
            @RequestParam BigDecimal unitPrice) {
        CbWalkinSession session = requireSession(id);
        CbOrder order = requireOrder(orderId, id);
        if (order.getStatus() == 6) throw new BusinessException("服务已完成，无法修改价格");
        order.setOriginalAmount(unitPrice);
        order.setPayAmount(unitPrice);
        orderMapper.updateById(order);
        refreshSessionTotal(session);
        return Result.success();
    }

    // ── 8. 开始服务 ────────────────────────────────────────────────────────────────

    @Operation(summary = "开始服务（设置 start_time，更新状态为服务中）")
    @PostMapping("/{id}/items/{orderId}/start")
    public Result<Void> startService(@PathVariable Long id, @PathVariable Long orderId) {
        CbWalkinSession session = requireSession(id);
        CbOrder order = requireOrder(orderId, id);
        if (order.getStatus() != 2 && order.getStatus() != 1)
            throw new BusinessException("当前状态无法开始服务");
        order.setStatus(5);       // 服务中
        order.setStartTime(LocalDateTime.now());
        orderMapper.updateById(order);

        if (session.getStatus() == 0) {
            session.setStatus(1); // 接待中 → 服务中
            sessionMapper.updateById(session);
        }
        return Result.success();
    }

    // ── 9. 结束单项服务 ────────────────────────────────────────────────────────────

    @Operation(summary = "结束服务项")
    @PostMapping("/{id}/items/{orderId}/finish")
    public Result<Void> finishService(@PathVariable Long id, @PathVariable Long orderId) {
        CbWalkinSession session = requireSession(id);
        CbOrder order = requireOrder(orderId, id);
        if (order.getStatus() != 5) throw new BusinessException("服务未进行中，无法结束");
        order.setStatus(6);       // 已完成
        order.setEndTime(LocalDateTime.now());
        orderMapper.updateById(order);

        // 若所有服务均已完成，session 进入待结算
        List<CbOrder> orders = listSessionOrders(id);
        boolean allDone = orders.stream().allMatch(o -> o.getStatus() == 6);
        if (allDone && session.getStatus() == 1) {
            session.setStatus(2); // 服务中 → 待结算
            sessionMapper.updateById(session);
        }
        return Result.success();
    }

    // ── 10. 结算（收款）──────────────────────────────────────────────────────────────

    @Operation(summary = "前台结算（收款）")
    @PostMapping("/{id}/settle")
    public Result<Void> settle(
            @PathVariable Long id,
            @RequestParam BigDecimal paidAmount,
            @RequestParam(required = false) String remark) {

        CbWalkinSession session = requireSession(id);
        if (session.getStatus() == 3) throw new BusinessException("已结算，无法重复操作");
        if (session.getStatus() == 4) throw new BusinessException("已取消");

        session.setPaidAmount(paidAmount);
        session.setStatus(3);     // 已结算
        session.setCheckOutTime(LocalDateTime.now());
        if (remark != null) session.setRemark(remark);
        sessionMapper.updateById(session);

        // 更新所有关联订单的 pay_time / status（确保结算状态同步）
        List<CbOrder> orders = listSessionOrders(id);
        for (CbOrder o : orders) {
            if (o.getStatus() != 7) {   // 排除已取消
                if (o.getStatus() != 6) {
                    o.setStatus(6);
                    o.setEndTime(LocalDateTime.now());
                }
                o.setPayTime(LocalDateTime.now());
                orderMapper.updateById(o);
            }
        }
        return Result.success();
    }

    // ── 11. 取消接待 ───────────────────────────────────────────────────────────────

    @Operation(summary = "取消接待")
    @PostMapping("/{id}/cancel")
    public Result<Void> cancel(
            @PathVariable Long id,
            @RequestParam(required = false) String reason) {

        CbWalkinSession session = requireSession(id);
        if (session.getStatus() == 3) throw new BusinessException("已结算，无法取消");
        if (session.getStatus() == 4) throw new BusinessException("已取消");

        // 只有没有进行中服务项时才允许取消
        List<CbOrder> orders = listSessionOrders(id);
        boolean hasActive = orders.stream().anyMatch(o -> o.getStatus() == 5);
        if (hasActive) throw new BusinessException("存在进行中的服务项，无法取消");

        session.setStatus(4);
        session.setRemark(reason != null ? reason : "");
        session.setCheckOutTime(LocalDateTime.now());
        sessionMapper.updateById(session);

        // 取消所有关联待服务订单
        for (CbOrder o : orders) {
            if (o.getStatus() != 6) {
                o.setStatus(7);
                o.setCancelReason(reason != null ? reason : "接待取消");
                orderMapper.updateById(o);
            }
        }
        return Result.success();
    }

    // ── 内部辅助方法 ───────────────────────────────────────────────────────────────

    private CbWalkinSession requireSession(Long id) {
        Long merchantId = MerchantContext.getMerchantId();
        CbWalkinSession session = sessionMapper.selectById(id);
        if (session == null) throw new BusinessException("接待记录不存在");
        if (!merchantId.equals(session.getMerchantId()))
            throw new BusinessException("无权访问该接待记录");
        return session;
    }

    private CbOrder requireOrder(Long orderId, Long sessionId) {
        CbOrder order = orderMapper.selectById(orderId);
        if (order == null || !sessionId.equals(order.getSessionId()))
            throw new BusinessException("服务项不存在");
        return order;
    }

    private List<CbOrder> listSessionOrders(Long sessionId) {
        return orderMapper.selectList(Wrappers.<CbOrder>lambdaQuery()
                .eq(CbOrder::getSessionId, sessionId)
                .eq(CbOrder::getOrderType, 2)
                .orderByAsc(CbOrder::getCreateTime));
    }

    /** 重新汇总 session 的 total_amount */
    private void refreshSessionTotal(CbWalkinSession session) {
        BigDecimal total = listSessionOrders(session.getId()).stream()
                .filter(o -> o.getStatus() != 7)
                .map(CbOrder::getPayAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        session.setTotalAmount(total);
        sessionMapper.updateById(session);
    }

    /** CbWalkinSession → Map（前端 VO） */
    private Map<String, Object> sessionToVO(CbWalkinSession s,
                                            List<Map<String, Object>> items) {        Map<String, Object> vo = new LinkedHashMap<>();
        vo.put("id",               s.getId());
        vo.put("sessionNo",        s.getSessionNo());
        vo.put("wristbandNo",      s.getWristbandNo());
        vo.put("memberName",       s.getMemberName());
        vo.put("memberMobile",     s.getMemberMobile());
        vo.put("technicianId",     s.getTechnicianId());
        vo.put("technicianName",   s.getTechnicianName());
        vo.put("technicianNo",     s.getTechnicianNo());
        vo.put("technicianMobile", s.getTechnicianMobile());
        vo.put("status",           s.getStatus());
        vo.put("totalAmount",      s.getTotalAmount());
        vo.put("paidAmount",       s.getPaidAmount());
        vo.put("checkInTime",      s.getCheckInTime() != null
                ? s.getCheckInTime().toString().replace("T", " ") : null);
        vo.put("checkOutTime",     s.getCheckOutTime() != null
                ? s.getCheckOutTime().toString().replace("T", " ") : null);
        vo.put("remark",           s.getRemark());
        vo.put("orderItems",       items);
        return vo;
    }

    /**
     * CbOrder → Map（服务项 VO）
     *
     * <p>字段映射：
     * <pre>
     *   serviceId   ← serviceItemId
     *   name        ← serviceName
     *   duration    ← serviceDuration
     *   unitPrice   ← payAmount
     *   svcStatus   ← dbStatusToSvcStatus(status)   (前端进度条的核心字段)
     *   startTime   ← startTime                     (进度条起始点)
     *   endTime     ← endTime
     * </pre>
     */
    private Map<String, Object> orderToItemVO(CbOrder o) {
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("orderId",    o.getId());
        item.put("orderNo",    o.getOrderNo());
        item.put("serviceId",  o.getServiceItemId());
        item.put("name",       o.getServiceName());
        item.put("duration",   o.getServiceDuration() != null ? o.getServiceDuration() : 0);
        item.put("unitPrice",  o.getPayAmount() != null ? o.getPayAmount().doubleValue() : 0.0);
        item.put("qty",        1);
        item.put("svcStatus",  dbStatusToSvcStatus(o.getStatus()));
        item.put("startTime",  o.getStartTime() != null
                ? o.getStartTime().toString().replace("T", " ") : null);
        item.put("endTime",    o.getEndTime() != null
                ? o.getEndTime().toString().replace("T", " ") : null);
        item.put("dbStatus",   o.getStatus());
        return item;
    }

    /**
     * 从 item map 构建 CbOrder（供 createWithItems 和 addItem 共享逻辑）
     */
    private CbOrder buildOrderFromItem(CbWalkinSession session, Map<String, Object> item, int idx) {
        String orderNo = session.getSessionNo() + "-" + String.format("%02d", idx);
        Object priceObj = item.get("unitPrice");
        BigDecimal unitPrice = priceObj == null ? BigDecimal.ZERO
                : (priceObj instanceof BigDecimal ? (BigDecimal) priceObj
                   : new BigDecimal(priceObj.toString()));

        CbOrder order = new CbOrder();
        order.setOrderType(2);
        order.setSessionId(session.getId());
        order.setWristbandNo(session.getWristbandNo());
        order.setOrderNo(orderNo);
        order.setMerchantId(session.getMerchantId());
        order.setMemberId(0L);             // 散客不关联会员，0 满足 NOT NULL
        order.setTechnicianId(session.getTechnicianId());
        Object svcIdObj = item.get("serviceItemId");
        order.setServiceItemId(svcIdObj == null ? 0L : Long.parseLong(svcIdObj.toString()));
        order.setServiceName(String.valueOf(item.getOrDefault("serviceName", "")));
        Object durObj = item.get("serviceDuration");
        order.setServiceDuration(durObj == null ? 0 : Integer.parseInt(durObj.toString()));
        order.setAddressId(0L);
        order.setAddressDetail("店内服务");
        order.setAppointTime(LocalDateTime.now());
        order.setOriginalAmount(unitPrice);
        order.setPayAmount(unitPrice);
        order.setStatus(2);   // 已确认，待服务
        return order;
    }

    /**
     * 简单解析服务项 JSON 字符串（避免引入额外 JSON 依赖，用 Spring 内置的方式）
     * 格式：[{"serviceItemId":1,"serviceName":"推拿","serviceDuration":60,"unitPrice":288}]
     */
    @SuppressWarnings("unchecked")
    private List<Map<String, Object>> parseItemsJson(String json) {
        try {
            // 利用 Jackson（Spring Boot 已内置）反序列化
            com.fasterxml.jackson.databind.ObjectMapper mapper =
                    new com.fasterxml.jackson.databind.ObjectMapper();
            return mapper.readValue(json,
                    mapper.getTypeFactory().constructCollectionType(List.class, Map.class));
        } catch (Exception e) {
            throw new BusinessException("服务项格式错误：" + e.getMessage());
        }
    }
}
