package com.cambook.dao.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.cambook.dao.entity.base.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 部门表
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("sys_dept")
public class SysDept extends BaseEntity {
    /** 归属商户ID（null=平台级别） */
    private Long merchantId;
    private Long parentId;
    private String name;
    private Integer sort;
    private String leader;
    private String phone;
    private String email;
    private Integer status;
}
