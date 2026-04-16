package com.cambook.app.domain.vo;

import com.cambook.dao.entity.CbOrder;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

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

    @Schema(description = "会员 ID")
    private Long memberId;

    @Schema(description = "会员昵称")
    private String memberNickname;

    @Schema(description = "技师 ID")
    private Long technicianId;

    @Schema(description = "技师昵称")
    private String technicianNickname;

    @Schema(description = "服务项名称快照")
    private String serviceName;

    @Schema(description = "服务时长（分钟）")
    private Integer serviceDuration;

    @Schema(description = "地址快照")
    private String addressDetail;

    @Schema(description = "预约时间")
    private LocalDateTime appointTime;

    @Schema(description = "原始金额")
    private BigDecimal originalAmount;

    @Schema(description = "优惠金额")
    private BigDecimal discountAmount;

    @Schema(description = "实付金额")
    private BigDecimal payAmount;

    @Schema(description = "支付方式：1ABA 2USDT 3余额 4现金")
    private Integer payType;

    @Schema(description = "订单状态")
    private Integer status;

    @Schema(description = "是否已评价")
    private Integer isReviewed;

    @Schema(description = "备注")
    private String remark;

    @Schema(description = "下单时间")
    private LocalDateTime createTime;

    public static OrderVO from(CbOrder o) {
        OrderVO vo = new OrderVO();
        vo.setId(o.getId());
        vo.setMerchantId(o.getMerchantId());
        vo.setOrderNo(o.getOrderNo());
        vo.setMemberId(o.getMemberId());
        vo.setTechnicianId(o.getTechnicianId());
        vo.setServiceName(o.getServiceName());
        vo.setServiceDuration(o.getServiceDuration());
        vo.setAddressDetail(o.getAddressDetail());
        vo.setAppointTime(o.getAppointTime());
        vo.setOriginalAmount(o.getOriginalAmount());
        vo.setDiscountAmount(o.getDiscountAmount());
        vo.setPayAmount(o.getPayAmount());
        vo.setPayType(o.getPayType());
        vo.setStatus(o.getStatus());
        vo.setIsReviewed(o.getIsReviewed());
        vo.setRemark(o.getRemark());
        vo.setCreateTime(o.getCreateTime());
        return vo;
    }
}
