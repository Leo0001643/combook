package com.cambook.dao.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.cambook.dao.entity.base.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 商户公告
 *
 * <p>type：1=内部公告（员工可见），2=客户公告（会员可见）
 * <p>targetType：1=本部门，2=全商户
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("merchant_announcement")
public class MerchantAnnouncement extends BaseEntity {

    private Long    merchantId;
    private Long    deptId;
    private String  deptName;
    private String  title;
    private String  content;
    /** 1=内部公告  2=客户公告 */
    private Integer type;
    /** 1=本部门  2=全商户 */
    private Integer targetType;
    /** 0=草稿  1=已发布 */
    private Integer status;
    private String  createBy;
}
