package com.cambook.dao.entity;

import lombok.Getter;
import lombok.Setter;

import com.baomidou.mybatisplus.annotation.TableName;
import com.cambook.dao.entity.base.BaseEntity;

import java.math.BigDecimal;

/**
 * 在线订单服务项明细
 *
 * <p>支持"一单多项"：每条记录对应订单中的一个服务项目。
 *
 * @author CamBook
 */
@TableName("cb_order_item")
@Getter
@Setter
public class CbOrderItem extends BaseEntity {

    private Long        orderId;
    private Long        serviceItemId;
    private String      serviceName;
    private Integer     serviceDuration;
    private BigDecimal  unitPrice;
    private Integer     qty;
    /** 0=待服务 1=服务中 2=已完成 */
    private Integer    svcStatus;
    private Long       startTime;
    private Long       endTime;
    private String     remark;
}
