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
 * 商户公告
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("merchant_announcement")
public class MerchantAnnouncement implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 所属商户
     */
    private Long merchantId;

    /**
     * 发布部门ID（NULL=商户级别）
     */
    private Long deptId;

    /**
     * 发布部门名称
     */
    private String deptName;

    /**
     * 公告标题
     */
    private String title;

    /**
     * 公告内容（富文本HTML）
     */
    private String content;

    /**
     * 类型：1=内部公告 2=客户公告
     */
    private Byte type;

    /**
     * 发送范围：1=本部门 2=全商户
     */
    private Byte targetType;

    /**
     * 状态：0=草稿 1=已发布
     */
    private Byte status;

    /**
     * 发布人
     */
    private String createBy;

    /**
     * 逻辑删除
     */
    private Byte deleted;

    /**
     * 创建时间（UTC 秒级时间戳）
     */
    private Long createTime;

    /**
     * 更新时间（UTC 秒级时间戳）
     */
    private Long updateTime;
}
