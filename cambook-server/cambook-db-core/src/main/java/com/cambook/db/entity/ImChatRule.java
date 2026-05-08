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
 * IM 通信权限规则表：角色粒度，商户可在平台默认规则基础上覆盖
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-06
 */
@Getter
@Setter
@ToString
@TableName("im_chat_rule")
public class ImChatRule implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 商户 ID，0 = 平台默认规则；商户可覆盖
     */
    private Long merchantId;

    /**
     * 发送方 IM 角色
     */
    private String senderRole;

    /**
     * 接收方 IM 角色
     */
    private String receiverRole;

    /**
     * 1=允许 0=禁止
     */
    private Byte allowed;

    private Long createTime;

    private Long updateTime;
}
