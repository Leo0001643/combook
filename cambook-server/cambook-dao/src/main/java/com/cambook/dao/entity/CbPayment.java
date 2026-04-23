package com.cambook.dao.entity;

import lombok.Getter;
import lombok.Setter;

import com.baomidou.mybatisplus.annotation.TableName;
import com.cambook.dao.entity.base.BaseEntity;

import java.math.BigDecimal;

/**
 * 支付记录实体
 *
 * <p>每笔订单支付对应一条记录，策略模式通过 payType 路由不同支付处理器。
 *
 * @author CamBook
 */
@TableName("cb_payment")
@Getter
@Setter
public class CbPayment extends BaseEntity {

    private String        paymentNo;
    private Long          orderId;
    private Long          memberId;
    private BigDecimal    amount;
    /** 支付方式：1-ABA  2-USDT  3-余额  4-现金 */
    private Integer       payType;
    /** 支付状态：0-待支付  1-支付成功  2-支付失败  3-已退款 */
    private Integer       status;
    /** 第三方支付流水号 */
    private String        thirdPartyNo;
    /** 第三方支付原始响应（JSON） */
    private String        rawResponse;
    private Long          payTime;

    public String        getPaymentNo()                  { return paymentNo; }
    public void          setPaymentNo(String v)          { this.paymentNo = v; }
    public Long          getOrderId()                    { return orderId; }
    public void          setOrderId(Long v)              { this.orderId = v; }
    public Long          getMemberId()                   { return memberId; }
    public void          setMemberId(Long v)             { this.memberId = v; }
    public BigDecimal    getAmount()                     { return amount; }
    public void          setAmount(BigDecimal v)         { this.amount = v; }
    public Integer       getPayType()                    { return payType; }
    public void          setPayType(Integer v)           { this.payType = v; }
    public Integer       getStatus()                     { return status; }
    public void          setStatus(Integer v)            { this.status = v; }
    public String        getThirdPartyNo()               { return thirdPartyNo; }
    public void          setThirdPartyNo(String v)       { this.thirdPartyNo = v; }
    public String        getRawResponse()                { return rawResponse; }
    public void          setRawResponse(String v)        { this.rawResponse = v; }
    public Long          getPayTime()                    { return payTime; }
    public void          setPayTime(Long v)              { this.payTime = v; }
}
