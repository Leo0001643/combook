package com.cambook.app.domain.vo.chat;

import lombok.Data;

/**
 * 媒体文件上传结果
 */
@Data
public class ImMediaVO {
    private Long    id;
    private String  fileType;
    private String  originalName;
    private String  fileUrl;
    private Long    fileSize;
    private Integer width;
    private Integer height;
    private Integer duration;
    private String  mimeType;
}
