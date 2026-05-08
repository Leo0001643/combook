package com.cambook.app.domain.dto.chat;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * 新增/更新商户 IM 通信权限规则请求体
 */
@Data
@Schema(description = "IM 权限规则 DTO")
public class ImChatRuleDTO {

    @NotBlank(message = "发送方角色不能为空")
    @Schema(description = "发送方 IM 角色（OWNER/MANAGER/STAFF/OPERATOR/MARKETING/TECHNICIAN/DRIVER/MEMBER/SUPER_ADMIN）")
    private String senderRole;

    @NotBlank(message = "接收方角色不能为空")
    @Schema(description = "接收方 IM 角色")
    private String receiverRole;

    @Schema(description = "true=允许发送 false=禁止发送", defaultValue = "true")
    private boolean allowed = true;
}
