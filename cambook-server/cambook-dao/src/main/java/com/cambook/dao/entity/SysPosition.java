package com.cambook.dao.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.cambook.dao.entity.base.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 后台职位表（对应 sys_position）
 *
 * @author CamBook
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("sys_position")
public class SysPosition extends BaseEntity {

    /** 归属商户ID（null=平台级别） */
    private Long merchantId;

    /** 所属部门ID */
    private Long deptId;

    /** 职位名称 */
    private String name;

    /** 职位编码（全局唯一，如 OP_DIRECTOR） */
    private String code;

    /** 备注说明 */
    private String remark;

    /** 排序（越小越前） */
    private Integer sort;

    /** 状态：1=启用 0=停用 */
    private Integer status;

    /** 全量权限标记：1=该职位拥有所有菜单权限（如总裁/董事长），无需单独分配 */
    private Integer fullAccess;
}
