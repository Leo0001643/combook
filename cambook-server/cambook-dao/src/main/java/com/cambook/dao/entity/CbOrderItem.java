package com.cambook.dao.entity;

import lombok.Getter;
import lombok.Setter;

import com.baomidou.mybatisplus.annotation.TableName;
import com.cambook.dao.entity.base.BaseEntity;

import java.math.BigDecimal;

/**
 * 在线订单服务项明细
 *
 * <p>支持"一单多项，多技师并行"：
 * <ul>
 *   <li>每条记录对应订单中的一个服务项目</li>
 *   <li>每个服务项可以指定不同的技师（{@code technicianId}）</li>
 *   <li>多名技师可同时执行同一订单中各自负责的项目（并行服务）</li>
 * </ul>
 *
 * @author CamBook
 */
@TableName("cb_order_item")
@Getter
@Setter
public class CbOrderItem extends BaseEntity {

    private Long        orderId;
    /** 执行该服务项的技师 ID（关联 cb_technician.id） */
    private Long        technicianId;
    private Long        serviceItemId;
    private String      serviceName;
    private Integer     serviceDuration;
    private BigDecimal  unitPrice;
    private Integer     qty;
    /** 0=待服务 1=服务中 2=已完成 */
    private Integer     svcStatus;
    /** 技师实际收入（扣佣后，结算时写入） */
    private BigDecimal  techIncome;
    private Long        startTime;
    private Long        endTime;
    private String      remark;
}
