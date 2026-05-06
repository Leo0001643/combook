package com.cambook.db.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;

/**
 * IM 群成员表
 */
@Data
@TableName("im_group_member")
public class ImGroupMember implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /** 群组 ID */
    private Long groupId;

    /** 成员类型：member / technician / merchant */
    private String userType;

    /** 成员 ID */
    private Long userId;

    /** 群内昵称（空则使用原昵称） */
    private String groupAlias;

    /** 角色：0=普通成员 1=管理员 2=群主 */
    private Byte role;

    /** 是否禁言：0=否 1=是 */
    private Byte isMuted;

    /** 状态：0=正常 1=已退群 */
    private Byte status;

    /** 加入时间戳（秒） */
    private Long joinedAt;

    /** 更新时间戳（秒） */
    private Long updateTime;
}
