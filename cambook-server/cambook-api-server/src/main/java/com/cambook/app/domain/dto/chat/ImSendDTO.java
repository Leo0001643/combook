package com.cambook.app.domain.dto.chat;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * 单聊消息发送请求
 */
@Data
public class ImSendDTO {

    /** 客户端消息 ID（幂等去重，可选） */
    private String clientMsgId;

    @NotBlank(message = "receiverType 不能为空")
    private String receiverType;

    @NotNull(message = "receiverId 不能为空")
    private Long receiverId;

    /** 消息类型：1=文本 2=图片 3=语音 4=视频 5=文件 */
    @NotNull(message = "msgType 不能为空")
    private Integer msgType;

    /**
     * 消息内容（JSON 字符串）：
     * - 文本：{"text":"hello"}
     * - 图片：{"mediaId":1,"url":"...","width":400,"height":300}
     * - 语音：{"mediaId":1,"url":"...","duration":10}
     */
    @NotBlank(message = "content 不能为空")
    private String content;
}
