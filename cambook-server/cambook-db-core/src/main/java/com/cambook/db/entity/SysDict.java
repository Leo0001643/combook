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
 * 字典数据表：存储各字典类型的字典项及其多语言标签
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("sys_dict")
public class SysDict implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键，自增
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 所属字典类型，关联 sys_dict_type.dict_type
     */
    private String dictType;

    /**
     * 字典值（程序使用的实际值），如 1 / PENDING / ABA
     */
    private String dictValue;

    /**
     * 中文标签，必填
     */
    private String labelZh;

    /**
     * 英文标签
     */
    private String labelEn;

    /**
     * 越南文标签
     */
    private String labelVi;

    /**
     * 柬埔寨文标签
     */
    private String labelKm;

    /**
     * 日文标签
     */
    private String labelJa;

    /**
     * 韩文标签
     */
    private String labelKo;

    /**
     * 排序权重，值越小越靠前
     */
    private Integer sort;

    /**
     * 状态：1=启用 0=停用
     */
    private Byte status;

    /**
     * 附加信息：Ant Design Tag color / 品牌色 hex / 国旗 emoji 等
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
     * 逻辑删除：0=正常 1=已删除
     */
    private Byte deleted;
}
