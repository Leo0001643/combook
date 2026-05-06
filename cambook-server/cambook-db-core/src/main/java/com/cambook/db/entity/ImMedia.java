package com.cambook.db.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;

/**
 * IM 媒体文件表（图片/视频/语音/文件）
 */
@Data
@TableName("im_media")
public class ImMedia implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /** 上传者类型 */
    private String uploaderType;

    /** 上传者 ID */
    private Long uploaderId;

    /** 文件类型：image / voice / video / file */
    private String fileType;

    /** 原始文件名 */
    private String originalName;

    /** 存储类型：local / oss */
    private String storageType;

    /** 存储路径（本地相对路径 or OSS Key） */
    private String storagePath;

    /** 访问 URL */
    private String fileUrl;

    /** 文件大小（字节） */
    private Long fileSize;

    /** 图片宽度（px，图片类型有效） */
    private Integer width;

    /** 图片高度（px，图片类型有效） */
    private Integer height;

    /** 时长（秒，语音/视频有效） */
    private Integer duration;

    /** MIME 类型 */
    private String mimeType;

    /** 上传时间戳（秒） */
    private Long createTime;
}
