package com.cambook.dao.entity;

import lombok.Getter;
import lombok.Setter;

import com.baomidou.mybatisplus.annotation.TableName;
import com.cambook.dao.entity.base.BaseEntity;

import java.math.BigDecimal;

/**
 * 订单表
 *
 * @author CamBook
 */
@TableName("cb_order")
@Getter
@Setter
public class CbOrder extends BaseEntity {

    /** 订单类型：1=在线预约 2=散客上门 */
    private Integer orderType;
    /** 服务方式：1=上门服务 2=到店服务 */
    private Integer serviceMode;
    /** 散客接待 session ID（order_type=2 时有值） */
    private Long    sessionId;
    /** 手环编号（散客上门时） */
    private String  wristbandNo;
    private String orderNo;
    private Long memberId;
    private Long technicianId;
    /** 技师编号快照（上门服务时用于识别身份） */
    private String  technicianNo;
    /** 技师手机快照 */
    private String  technicianMobile;
    private Long merchantId;
    private Long serviceItemId;
    private String serviceName;
    private Integer serviceDuration;
    private Long addressId;
    private String addressDetail;
    private BigDecimal addressLat;
    private BigDecimal addressLng;
    private Long appointTime;
    private Long startTime;
    private Long endTime;
    private BigDecimal originalAmount;
    private BigDecimal discountAmount;
    private BigDecimal transportFee;
    private BigDecimal payAmount;
    private Long couponId;
    /** 支付方式：1ABA 2USDT 3余额 4现金 */
    private Integer payType;
    /** 组合支付明细 JSON（[{method,currency,amount}]） */
    private String  payRecords;
    private Long payTime;
    private BigDecimal techIncome;
    private BigDecimal platformIncome;
    /** 0待支付 1已支付 2接单 3前往 4到达 5服务中 6完成 7取消 8退款中 9已退款 */
    private Integer status;
    private String cancelReason;
    private String remark;
    private Integer isReviewed;

    public Long    getSessionId()           { return sessionId; }
    public String  getWristbandNo()         { return wristbandNo; }
    public String  getTechnicianNo()        { return technicianNo; }
    public String  getTechnicianMobile()    { return technicianMobile; }
    public String  getPayRecords()          { return payRecords; }

}
