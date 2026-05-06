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
 * 公告已读记录
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("merchant_announcement_read")
public class MerchantAnnouncementRead implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 公告ID
     */
    private Long announcementId;

    /**
     * 读者手机号
     */
    private String readerMobile;

    /**
     * 商户ID
     */
    private Long merchantId;

    /**
     * 已读时间（UTC 秒级时间戳）
     */
    private Long readTime;
}
