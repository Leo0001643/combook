package com.cambook.dao.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.cambook.dao.entity.base.BaseEntity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 在线订单服务项明细
 *
 * <p>支持"一单多项"：每条记录对应订单中的一个服务项目。
 *
 * @author CamBook
 */
@TableName("cb_order_item")
public class CbOrderItem extends BaseEntity {

    private Long        orderId;
    private Long        serviceItemId;
    private String      serviceName;
    private Integer     serviceDuration;
    private BigDecimal  unitPrice;
    private Integer     qty;
    /** 0=待服务 1=服务中 2=已完成 */
    private Integer     svcStatus;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private String      remark;

    public Long        getOrderId()          { return orderId; }
    public Long        getServiceItemId()     { return serviceItemId; }
    public String      getServiceName()       { return serviceName; }
    public Integer     getServiceDuration()   { return serviceDuration; }
    public BigDecimal  getUnitPrice()         { return unitPrice; }
    public Integer     getQty()               { return qty; }
    public Integer     getSvcStatus()         { return svcStatus; }
    public LocalDateTime getStartTime()       { return startTime; }
    public LocalDateTime getEndTime()         { return endTime; }
    public String      getRemark()            { return remark; }

    public void setOrderId(Long orderId)                    { this.orderId = orderId; }
    public void setServiceItemId(Long serviceItemId)        { this.serviceItemId = serviceItemId; }
    public void setServiceName(String serviceName)          { this.serviceName = serviceName; }
    public void setServiceDuration(Integer serviceDuration) { this.serviceDuration = serviceDuration; }
    public void setUnitPrice(BigDecimal unitPrice)          { this.unitPrice = unitPrice; }
    public void setQty(Integer qty)                         { this.qty = qty; }
    public void setSvcStatus(Integer svcStatus)             { this.svcStatus = svcStatus; }
    public void setStartTime(LocalDateTime startTime)       { this.startTime = startTime; }
    public void setEndTime(LocalDateTime endTime)           { this.endTime = endTime; }
    public void setRemark(String remark)                    { this.remark = remark; }
}
