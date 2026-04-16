package com.cambook.dao.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.cambook.dao.entity.base.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 字典数据表
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("sys_dict_data")
public class SysDictData extends BaseEntity {
    private String dictType;
    private String dictLabel;
    private String dictValue;
    private Integer sort;
    private Integer isDefault;
    private String cssClass;
    private Integer status;
    private String remark;
}
