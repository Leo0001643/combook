package com.cambook.app.domain.dto.chat;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import lombok.Data;

import java.util.List;

/**
 * 创建群组请求
 */
@Data
public class ImCreateGroupDTO {

    @NotBlank(message = "群名称不能为空")
    private String name;

    private String avatar;
    private String description;

    @NotEmpty(message = "至少需要一个群成员")
    private List<MemberItem> members;

    @Data
    public static class MemberItem {
        private String userType;
        private Long   userId;
    }
}
