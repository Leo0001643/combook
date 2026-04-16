package com.cambook.dao.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 公告已读记录
 */
@Data
@TableName("merchant_announcement_read")
public class MerchantAnnouncementRead implements Serializable {

    private Long          id;
    private Long          announcementId;
    /** 读者手机号（作为唯一标识） */
    private String        readerMobile;
    private Long          merchantId;
    private LocalDateTime readTime;
}
