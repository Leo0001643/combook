package com.cambook.dao.entity;

import lombok.Getter;
import lombok.Setter;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.cambook.dao.entity.base.BaseEntity;

import java.math.BigDecimal;

/**
 * 散客接待 Session 实体
 *
 * <p>一次到店 = 一个 session，手环是识别载体。
 * 每项消费对应 {@link CbOrder}（order_type=2，session_id 关联）。
 *
 * <pre>
 * status:
 *   0 = 接待中（已录入，尚未开始服务）
 *   1 = 服务中（至少一项服务已开始）
 *   2 = 待结算（所有服务已完成，等待前台收款）
 *   3 = 已结算
 *   4 = 已取消
 * </pre>
 *
 * @author CamBook
 */
@TableName("cb_walkin_session")
@Getter
@Setter
public class CbWalkinSession extends BaseEntity {

    private String      sessionNo;
    private String      wristbandNo;
    private Long        merchantId;
    private Long        memberId;
    private String      memberName;
    private String      memberMobile;
    private Long        staffId;
    private Long        technicianId;
    private String      technicianName;
    private String      technicianNo;
    private String      technicianMobile;
    private Integer     status;
    private BigDecimal  totalAmount;
    private BigDecimal  paidAmount;
    private String      remark;
    private Long        checkInTime;
    private Long        checkOutTime;
    /** 技师实际开始服务时间（Unix 秒）。需先执行 migrate_v5_6 添加 DB 列后才生效。 */
    @TableField(exist = false)
    private Long        serviceStartTime;

    public String getSessionNo()           { return sessionNo; }
    public String getWristbandNo()         { return wristbandNo; }
    public Long getMerchantId()            { return merchantId; }
    public Long getMemberId()              { return memberId; }
    public String getMemberName()          { return memberName; }
    public String getMemberMobile()        { return memberMobile; }
    public Long getStaffId()               { return staffId; }
    public Long getTechnicianId()          { return technicianId; }
    public String getTechnicianName()      { return technicianName; }
    public String getTechnicianNo()        { return technicianNo; }
    public String getTechnicianMobile()    { return technicianMobile; }
    public Integer getStatus()             { return status; }
    public BigDecimal getTotalAmount()     { return totalAmount; }
    public BigDecimal getPaidAmount()      { return paidAmount; }
    public String getRemark()              { return remark; }
    public Long getCheckInTime()           { return checkInTime; }
    public Long getCheckOutTime()          { return checkOutTime; }
    public Long getServiceStartTime()      { return serviceStartTime; }

    public void setSessionNo(String sessionNo)               { this.sessionNo = sessionNo; }
    public void setWristbandNo(String wristbandNo)           { this.wristbandNo = wristbandNo; }
    public void setMerchantId(Long merchantId)               { this.merchantId = merchantId; }
    public void setMemberId(Long memberId)                   { this.memberId = memberId; }
    public void setMemberName(String memberName)             { this.memberName = memberName; }
    public void setMemberMobile(String memberMobile)         { this.memberMobile = memberMobile; }
    public void setStaffId(Long staffId)                     { this.staffId = staffId; }
    public void setTechnicianId(Long technicianId)           { this.technicianId = technicianId; }
    public void setTechnicianName(String technicianName)     { this.technicianName = technicianName; }
    public void setTechnicianNo(String technicianNo)         { this.technicianNo = technicianNo; }
    public void setStatus(Integer status)                    { this.status = status; }
    public void setTotalAmount(BigDecimal totalAmount)       { this.totalAmount = totalAmount; }
    public void setPaidAmount(BigDecimal paidAmount)         { this.paidAmount = paidAmount; }
    public void setRemark(String remark)                     { this.remark = remark; }
    public void setCheckInTime(Long checkInTime)             { this.checkInTime = checkInTime; }
    public void setCheckOutTime(Long checkOutTime)           { this.checkOutTime = checkOutTime; }
    public void setServiceStartTime(Long serviceStartTime)   { this.serviceStartTime = serviceStartTime; }
}
