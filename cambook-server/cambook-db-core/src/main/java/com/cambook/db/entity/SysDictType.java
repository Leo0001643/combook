package com.cambook.db.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.io.Serializable;

/**
 * <p>
 * 字典类型表：管理所有枚举类型的元信息
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("sys_dict_type")
public class SysDictType implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键，自增
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 字典类型唯一标识（英文小写+下划线），如 order_status / pay_type
     */
    private String dictType;

    /**
     * 字典类型名称（中文可读），如 订单状态
     */
    private String dictName;

    /**
     * 状态：1=启用 0=停用
     */
    private Byte status;

    /**
     * 备注说明，可为空
     */
    private String remark;

    /**
     * 创建时间（UTC 秒级时间戳）
     */
    private Long createTime;

    /**
     * 最后修改时间（UTC 秒级时间戳）
     */
    private Long updateTime;

    /**
     * 逻辑删除
     */
    private Byte deleted;
}
