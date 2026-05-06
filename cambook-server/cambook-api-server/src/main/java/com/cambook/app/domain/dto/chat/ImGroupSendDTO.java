package com.cambook.app.domain.dto.chat;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * 群聊消息发送请求
 */
@Data
public class ImGroupSendDTO {

    private String clientMsgId;

    @NotNull(message = "groupId 不能为空")
    private Long groupId;

    @NotNull(message = "msgType 不能为空")
    private Integer msgType;

    @NotBlank(message = "content 不能为空")
    private String content;
}
