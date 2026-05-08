package com.cambook.app.domain.vo.chat;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * IM 通讯录分组 VO（按角色分组展示）
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ImContactGroupVO {

    /** 分组标题，如 "领导层"、"运营/营销"、"技师" */
    private String groupName;

    /** 分组排序（越小越靠前） */
    private int sort;

    /** 该分组下的联系人列表 */
    private List<ImContactVO> contacts;
}
