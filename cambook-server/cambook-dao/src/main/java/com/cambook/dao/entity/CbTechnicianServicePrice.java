package com.cambook.dao.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 技师服务专属定价表
 * 特殊服务项目（is_special=1）支持技师自行覆盖系统指导价。
 */
@TableName("cb_technician_service_price")
public class CbTechnicianServicePrice implements Serializable {

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    private Long       merchantId;
    private Long       technicianId;
    private Long       serviceItemId;
    private BigDecimal price;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;

    public Long       getId()              { return id; }
    public void       setId(Long v)        { this.id = v; }

    public Long       getMerchantId()      { return merchantId; }
    public void       setMerchantId(Long v){ this.merchantId = v; }

    public Long       getTechnicianId()    { return technicianId; }
    public void       setTechnicianId(Long v){ this.technicianId = v; }

    public Long       getServiceItemId()   { return serviceItemId; }
    public void       setServiceItemId(Long v){ this.serviceItemId = v; }

    public BigDecimal getPrice()           { return price; }
    public void       setPrice(BigDecimal v){ this.price = v; }

    public LocalDateTime getCreateTime()   { return createTime; }
    public void          setCreateTime(LocalDateTime v){ this.createTime = v; }

    public LocalDateTime getUpdateTime()   { return updateTime; }
    public void          setUpdateTime(LocalDateTime v){ this.updateTime = v; }
}
