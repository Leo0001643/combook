package com.cambook.app.domain.vo;

import com.cambook.dao.entity.CbOrder;
import com.cambook.dao.entity.CbOrderItem;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

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
    private LocalDateTime appointTime;

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
    private LocalDateTime createTime;

    @Schema(description = "服务开始时间")
    private LocalDateTime startTime;

    @Schema(description = "服务结束时间")
    private LocalDateTime endTime;

    @Schema(description = "多服务项明细列表")
    private List<OrderItemVO> orderItems;

    // ── 内嵌 VO ────────────────────────────────────────────────────────────────

    @Data
    public static class OrderItemVO {
        private Long        id;
        private Long        serviceItemId;
        private String      serviceName;
        private Integer     serviceDuration;
        private BigDecimal  unitPrice;
        private Integer     qty;
        private Integer     svcStatus;
        private LocalDateTime startTime;
        private LocalDateTime endTime;

        public static OrderItemVO from(CbOrderItem item) {
            OrderItemVO vo = new OrderItemVO();
            vo.setId(item.getId());
            vo.setServiceItemId(item.getServiceItemId());
            vo.setServiceName(item.getServiceName());
            vo.setServiceDuration(item.getServiceDuration());
            vo.setUnitPrice(item.getUnitPrice());
            vo.setQty(item.getQty());
            vo.setSvcStatus(item.getSvcStatus());
            vo.setStartTime(item.getStartTime());
            vo.setEndTime(item.getEndTime());
            return vo;
        }
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
