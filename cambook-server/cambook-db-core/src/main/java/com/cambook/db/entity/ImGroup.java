package com.cambook.db.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;

/**
 * IM 群组表
 */
@Data
@TableName("im_group")
public class ImGroup implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /** 群名称 */
    private String name;

    /** 群头像 URL */
    private String avatar;

    /** 群介绍 */
    private String description;

    /** 群主类型 */
    private String ownerType;

    /** 群主 ID */
    private Long ownerId;

    /** 当前成员数 */
    private Integer memberCount;

    /** 最大成员数（默认 500） */
    private Integer maxMember;

    /** 状态：0=正常 1=已解散 */
    private Byte status;

    /** 创建时间戳（秒） */
    private Long createTime;

    /** 更新时间戳（秒） */
    private Long updateTime;
}
