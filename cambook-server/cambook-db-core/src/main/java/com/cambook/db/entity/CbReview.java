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
 * 订单评价表：多维度评分+文字评价，每单一次，支持技师回复
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("cb_review")
public class CbReview implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键，自增
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 关联订单 ID，关联 cb_order.id（一单只能评一次）
     */
    private Long orderId;

    /**
     * 评价的会员 ID，关联 cb_member.id
     */
    private Long memberId;

    /**
     * 被评价的技师 ID，关联 cb_technician.id
     */
    private Long technicianId;

    /**
     * 综合评分（1-5星，影响技师总评分 rating）
     */
    private Byte overallScore;

    /**
     * 技术手法评分（1-5星）
     */
    private Byte techniqueScore;

    /**
     * 服务态度评分（1-5星）
     */
    private Byte attitudeScore;

    /**
     * 准时到达评分（1-5星）
     */
    private Byte punctualScore;

    /**
     * 文字评价内容（可为空，允许只评星）
     */
    private String content;

    /**
     * 评价标签 ID 列表（JSON Array，快捷标签如 技术专业/态度好）
     */
    private String tags;

    /**
     * 是否匿名评价：0=展示昵称 1=匿名显示
     */
    private Byte isAnonymous;

    /**
     * 技师回复内容
     */
    private String reply;

    /**
     * 技师回复时间（UTC 秒级时间戳）
     */
    private Long replyTime;

    /**
     * 状态：1=正常显示 0=已屏蔽（违规评价由运营屏蔽）
     */
    private Byte status;

    /**
     * 逻辑删除：0=正常 1=已删除
     */
    private Byte deleted;

    /**
     * 评价发布时间（UTC 秒级时间戳）
     */
    private Long createTime;

    /**
     * 最后修改时间（UTC 秒级时间戳）
     */
    private Long updateTime;
}
