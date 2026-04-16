package com.cambook.dao.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.cambook.dao.entity.base.BaseEntity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 派车单
 *
 * @author CamBook
 */
@TableName("cb_dispatch_order")
public class CbDispatchOrder extends BaseEntity {

    private String  dispatchNo;
    private Long    orderId;
    private Long    driverId;
    private Long    vehicleId;
    private BigDecimal pickupLat;
    private BigDecimal pickupLng;
    private BigDecimal destLat;
    private BigDecimal destLng;
    private String  destAddress;
    private LocalDateTime pickupTime;
    private LocalDateTime actualPickupTime;
    private LocalDateTime finishTime;
    /** 状态：0待接 1接单 2前往 3到达 4服务中 5完成 9取消 */
    private Integer status;
    private String  cancelReason;
    private String  remark;

    public String    getDispatchNo()                        { return dispatchNo; }
    public void      setDispatchNo(String dispatchNo)       { this.dispatchNo = dispatchNo; }

    public Long      getOrderId()                           { return orderId; }
    public void      setOrderId(Long orderId)               { this.orderId = orderId; }

    public Long      getDriverId()                          { return driverId; }
    public void      setDriverId(Long driverId)             { this.driverId = driverId; }

    public Long      getVehicleId()                         { return vehicleId; }
    public void      setVehicleId(Long vehicleId)           { this.vehicleId = vehicleId; }

    public BigDecimal getPickupLat()                        { return pickupLat; }
    public void       setPickupLat(BigDecimal pickupLat)    { this.pickupLat = pickupLat; }

    public BigDecimal getPickupLng()                        { return pickupLng; }
    public void       setPickupLng(BigDecimal pickupLng)    { this.pickupLng = pickupLng; }

    public BigDecimal getDestLat()                          { return destLat; }
    public void       setDestLat(BigDecimal destLat)        { this.destLat = destLat; }

    public BigDecimal getDestLng()                          { return destLng; }
    public void       setDestLng(BigDecimal destLng)        { this.destLng = destLng; }

    public String    getDestAddress()                       { return destAddress; }
    public void      setDestAddress(String destAddress)     { this.destAddress = destAddress; }

    public LocalDateTime getPickupTime()                    { return pickupTime; }
    public void          setPickupTime(LocalDateTime v)     { this.pickupTime = v; }

    public LocalDateTime getActualPickupTime()              { return actualPickupTime; }
    public void          setActualPickupTime(LocalDateTime v){ this.actualPickupTime = v; }

    public LocalDateTime getFinishTime()                    { return finishTime; }
    public void          setFinishTime(LocalDateTime v)     { this.finishTime = v; }

    public Integer   getStatus()                            { return status; }
    public void      setStatus(Integer status)              { this.status = status; }

    public String    getCancelReason()                      { return cancelReason; }
    public void      setCancelReason(String cancelReason)   { this.cancelReason = cancelReason; }

    public String    getRemark()                            { return remark; }
    public void      setRemark(String remark)               { this.remark = remark; }
}
