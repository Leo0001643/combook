package com.cambook.dao.entity;

import lombok.Getter;
import lombok.Setter;

import com.baomidou.mybatisplus.annotation.TableName;
import com.cambook.dao.entity.base.BaseEntity;

import java.math.BigDecimal;

/**
 * 派车单
 *
 * @author CamBook
 */
@TableName("cb_dispatch_order")
@Getter
@Setter
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
    private Long    pickupTime;
    private Long    actualPickupTime;
    private Long    finishTime;
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

    public void       setPickupLat(BigDecimal pickupLat)    { this.pickupLat = pickupLat; }

    public void       setPickupLng(BigDecimal pickupLng)    { this.pickupLng = pickupLng; }

    public void       setDestLat(BigDecimal destLat)        { this.destLat = destLat; }

    public void       setDestLng(BigDecimal destLng)        { this.destLng = destLng; }

    public String    getDestAddress()                       { return destAddress; }
    public void      setDestAddress(String destAddress)     { this.destAddress = destAddress; }

    public Long      getPickupTime()                        { return pickupTime; }
    public void      setPickupTime(Long v)                  { this.pickupTime = v; }

    public Long      getActualPickupTime()                  { return actualPickupTime; }
    public void      setActualPickupTime(Long v)            { this.actualPickupTime = v; }

    public Long      getFinishTime()                        { return finishTime; }
    public void      setFinishTime(Long v)                  { this.finishTime = v; }

    public Integer   getStatus()                            { return status; }
    public void      setStatus(Integer status)              { this.status = status; }

    public String    getCancelReason()                      { return cancelReason; }
    public void      setCancelReason(String cancelReason)   { this.cancelReason = cancelReason; }

    public String    getRemark()                            { return remark; }
    public void      setRemark(String remark)               { this.remark = remark; }
}
