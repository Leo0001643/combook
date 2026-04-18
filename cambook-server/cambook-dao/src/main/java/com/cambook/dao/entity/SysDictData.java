package com.cambook.dao.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.cambook.dao.entity.base.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 字典数据表（对应 sys_dict）
 *
 * <p>多语言标签：labelZh 必填，其余可选，前端降级展示。
 * remark 存 Ant Design Tag color / 品牌色 hex / 国旗 emoji 等附加信息。
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("sys_dict")
public class SysDictData extends BaseEntity {
    private String  dictType;
    private String  dictValue;
    /** 中文标签（必填） */
    private String  labelZh;
    private String  labelEn;
    private String  labelVi;
    private String  labelKm;
    private String  labelJa;
    private String  labelKo;
    private Integer sort;
    private Integer status;
    private String  remark;
}
