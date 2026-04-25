package com.cambook.app.domain.vo;

import com.cambook.dao.entity.CbOrder;
import com.cambook.dao.entity.CbOrderItem;
import com.cambook.dao.entity.CbServiceCategory;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 订单视图
 *
 * @author CamBook
 */
@Data
@Schema(description = "订单信息")
public class OrderVO {

    @Schema(description = "订单 ID")
    private Long id;

    @Schema(description = "所属商户 ID")
    private Long merchantId;

    @Schema(description = "订单号")
    private String orderNo;

    @Schema(description = "订单类型：1=在线预约 2=散客上门")
    private Integer orderType;

    @Schema(description = "服务方式：1=上门服务 2=到店服务")
    private Integer serviceMode;

    @Schema(description = "会员 ID")
    private Long memberId;

    @Schema(description = "会员昵称")
    private String memberNickname;

    @Schema(description = "会员手机")
    private String memberMobile;

    @Schema(description = "技师 ID")
    private Long technicianId;

    @Schema(description = "技师昵称")
    private String technicianNickname;

    @Schema(description = "技师编号")
    private String technicianNo;

    @Schema(description = "技师手机")
    private String technicianMobile;

    @Schema(description = "服务项名称快照（兼容单项）")
    private String serviceName;

    @Schema(description = "服务时长（分钟）")
    private Integer serviceDuration;

    @Schema(description = "地址快照（上门服务）")
    private String addressDetail;

    @Schema(description = "预约时间")
    private Long appointTime;

    @Schema(description = "原始金额")
    private BigDecimal originalAmount;

    @Schema(description = "优惠金额")
    private BigDecimal discountAmount;

    @Schema(description = "实付金额")
    private BigDecimal payAmount;

    @Schema(description = "支付方式：1现金 2微信 3支付宝 4银行转账 5USDT 6其它")
    private Integer payType;

    @Schema(description = "组合支付明细 JSON")
    private String payRecords;

    @Schema(description = "订单状态：0待支付 1待接单 2已接单 3前往 4到达 5服务中 6完成 7取消")
    private Integer status;

    @Schema(description = "取消原因")
    private String cancelReason;

    @Schema(description = "是否已评价")
    private Integer isReviewed;

    @Schema(description = "备注")
    private String remark;

    @Schema(description = "下单时间")
    private Long createTime;

    @Schema(description = "服务开始时间")
    private Long startTime;

    @Schema(description = "服务结束时间")
    private Long endTime;

    @Schema(description = "多服务项明细列表")
    private List<OrderItemVO> orderItems;

    // ── 内嵌 VO ────────────────────────────────────────────────────────────────

    @Data
    @Schema(description = "订单服务项明细")
    public static class OrderItemVO {

        @Schema(description = "服务项明细 ID")
        private Long        id;

        @Schema(description = "执行该项目的技师 ID")
        private Long        technicianId;

        @Schema(description = "服务项目 ID")
        private Long        serviceItemId;

        @Schema(description = "服务项名称快照")
        private String      serviceName;

        @Schema(description = "服务时长（分钟）")
        private Integer     serviceDuration;

        @Schema(description = "单价")
        private BigDecimal  unitPrice;

        @Schema(description = "数量")
        private Integer     qty;

        /** 0=待服务 1=服务中 2=已完成 */
        @Schema(description = "项目状态：0=待服务 1=服务中 2=已完成")
        private Integer     svcStatus;

        @Schema(description = "技师实际收入（结算后，null 表示未结算）")
        private BigDecimal  techIncome;

        @Schema(description = "服务开始时间")
        private Long        startTime;

        @Schema(description = "服务结束时间")
        private Long        endTime;

        @Schema(description = "备注")
        private String      remark;

        /**
         * 服务项名称多语言映射：{"zh":"全身按摩","en":"Full Body Massage","vi":...}
         * <p>调用方根据用户 locale 取对应语言，回退顺序：所选语言 → zh → serviceName 快照。
         */
        @Schema(description = "多语言名称 map，key=语言码(zh/en/vi/km/ja/ko)，value=名称")
        private Map<String, String> nameI18n;

        /**
         * 从 CbServiceCategory 中提取多语言名称，忽略 null/空值。
         */
        public static Map<String, String> buildNameI18n(CbServiceCategory cat) {
            if (cat == null) return null;
            Map<String, String> m = new LinkedHashMap<>(6);
            if (cat.getNameZh() != null && !cat.getNameZh().isBlank()) m.put("zh", cat.getNameZh());
            if (cat.getNameEn() != null && !cat.getNameEn().isBlank()) m.put("en", cat.getNameEn());
            if (cat.getNameVi() != null && !cat.getNameVi().isBlank()) m.put("vi", cat.getNameVi());
            if (cat.getNameKm() != null && !cat.getNameKm().isBlank()) m.put("km", cat.getNameKm());
            if (cat.getNameJa() != null && !cat.getNameJa().isBlank()) m.put("ja", cat.getNameJa());
            if (cat.getNameKo() != null && !cat.getNameKo().isBlank()) m.put("ko", cat.getNameKo());
            return m.isEmpty() ? null : m;
        }

        public static OrderItemVO from(CbOrderItem item) {
            OrderItemVO vo = new OrderItemVO();
            vo.setId(item.getId());
            vo.setTechnicianId(item.getTechnicianId());
            vo.setServiceItemId(item.getServiceItemId());
            vo.setServiceName(item.getServiceName());
            vo.setServiceDuration(item.getServiceDuration());
            vo.setUnitPrice(item.getUnitPrice());
            vo.setQty(item.getQty());
            vo.setSvcStatus(item.getSvcStatus());
            vo.setTechIncome(item.getTechIncome());
            vo.setStartTime(item.getStartTime());
            vo.setEndTime(item.getEndTime());
            vo.setRemark(item.getRemark());
            return vo;
        }

        /**
         * 从门店散客 CbOrder（order_type=2）构建服务项 VO。
         *
         * <p>walkin 场景中，每条 cb_order 就是一个服务项，status 映射：
         * <ul>
         *   <li>5 (服务中)  → svcStatus 1</li>
         *   <li>6 (已完成)  → svcStatus 2</li>
         *   <li>其它        → svcStatus 0 (待服务)</li>
         * </ul>
         */
        public static OrderItemVO fromWalkinOrder(CbOrder o) {
            int svcStatus = switch (o.getStatus() == null ? -1 : o.getStatus()) {
                case 5  -> 1;
                case 6  -> 2;
                default -> 0;
            };
            OrderItemVO vo = new OrderItemVO();
            vo.setId(o.getId());
            vo.setTechnicianId(o.getTechnicianId());
            vo.setServiceItemId(o.getServiceItemId());
            vo.setServiceName(o.getServiceName());
            vo.setServiceDuration(o.getServiceDuration() != null ? o.getServiceDuration() : 0);
            vo.setUnitPrice(o.getPayAmount());
            vo.setQty(1);
            vo.setSvcStatus(svcStatus);
            vo.setStartTime(o.getStartTime());
            vo.setEndTime(o.getEndTime());
            return vo;
        }
    }

    /** 构建含服务项明细的完整 OrderVO */
    public static OrderVO fromWithItems(CbOrder o, List<CbOrderItem> items) {
        OrderVO vo = from(o);
        vo.setOrderItems(items == null || items.isEmpty()
                ? Collections.emptyList()
                : items.stream().map(OrderItemVO::from).collect(Collectors.toList()));
        return vo;
    }

    public static OrderVO from(CbOrder o) {
        OrderVO vo = new OrderVO();
        vo.setId(o.getId());
        vo.setMerchantId(o.getMerchantId());
        vo.setOrderNo(o.getOrderNo());
        vo.setOrderType(o.getOrderType());
        vo.setServiceMode(o.getServiceMode());
        vo.setMemberId(o.getMemberId());
        vo.setTechnicianId(o.getTechnicianId());
        vo.setTechnicianNo(o.getTechnicianNo());
        vo.setTechnicianMobile(o.getTechnicianMobile());
        vo.setServiceName(o.getServiceName());
        vo.setServiceDuration(o.getServiceDuration());
        vo.setAddressDetail(o.getAddressDetail());
        vo.setAppointTime(o.getAppointTime());
        vo.setOriginalAmount(o.getOriginalAmount());
        vo.setDiscountAmount(o.getDiscountAmount());
        vo.setPayAmount(o.getPayAmount());
        vo.setPayType(o.getPayType());
        vo.setPayRecords(o.getPayRecords());
        vo.setStatus(o.getStatus());
        vo.setCancelReason(o.getCancelReason());
        vo.setIsReviewed(o.getIsReviewed());
        vo.setRemark(o.getRemark());
        vo.setCreateTime(o.getCreateTime());
        vo.setStartTime(o.getStartTime());
        vo.setEndTime(o.getEndTime());
        return vo;
    }
}
