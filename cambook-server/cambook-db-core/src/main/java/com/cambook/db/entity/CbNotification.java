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
 * 站内通知表：系统主动推送，多语言内容，含关联业务跳转
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("cb_notification")
public class CbNotification implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键，自增
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 消息接收方类型：1=会员 2=技师 3=商户
     */
    private Byte ownerType;

    /**
     * 消息接收方 ID（根据 owner_type 关联对应主表）
     */
    private Long ownerId;

    /**
     * 通知类型：1=系统公告 2=订单相关 3=活动营销
     */
    private Byte type;

    /**
     * 通知标题（中文）
     */
    private String titleZh;

    /**
     * 通知标题（英文）
     */
    private String titleEn;

    /**
     * 通知标题（越南文）
     */
    private String titleVi;

    /**
     * 通知标题（柬埔寨文）
     */
    private String titleKm;

    /**
     * 通知内容（中文，支持富文本）
     */
    private String contentZh;

    /**
     * 通知内容（英文）
     */
    private String contentEn;

    /**
     * 通知内容（越南文）
     */
    private String contentVi;

    /**
     * 通知内容（柬埔寨文）
     */
    private String contentKm;

    /**
     * 关联业务 ID（如订单 ID、活动 ID），前端用于跳转目标页面
     */
    private Long relateId;

    /**
     * 是否已读：0=未读 1=已读
     */
    private Byte isRead;

    /**
     * 通知推送时间（UTC 秒级时间戳）
     */
    private Long createTime;
}
