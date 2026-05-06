package com.cambook.app.domain.vo.chat;

import lombok.Data;

import java.util.List;

/**
 * 群组视图对象
 */
@Data
public class ImGroupVO {
    private Long    id;
    private String  name;
    private String  avatar;
    private String  description;
    private String  ownerType;
    private Long    ownerId;
    private Integer memberCount;
    private Integer maxMember;
    private Long    createTime;
    private List<MemberItem> members;

    @Data
    public static class MemberItem {
        private String userType;
        private Long   userId;
        private String nickname;
        private String avatar;
        private Byte   role;
        private String groupAlias;
    }
}
