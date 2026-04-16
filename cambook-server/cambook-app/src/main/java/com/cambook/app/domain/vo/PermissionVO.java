package com.cambook.app.domain.vo;

import com.cambook.dao.entity.SysPermission;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 权限树节点视图
 *
 * @author CamBook
 */
@Data
@Schema(description = "权限树节点")
public class PermissionVO {

    @Schema(description = "主键")
    private Long id;

    @Schema(description = "父节点 ID")
    private Long parentId;

    @Schema(description = "权限名称")
    private String name;

    @Schema(description = "权限编码")
    private String code;

    @Schema(description = "类型：1目录 2菜单 3按钮")
    private Integer type;

    @Schema(description = "图标")
    private String icon;

    @Schema(description = "路由路径")
    private String path;

    @Schema(description = "组件路径")
    private String component;

    @Schema(description = "排序")
    private Integer sort;

    @Schema(description = "是否显示")
    private Integer visible;

    @Schema(description = "子节点")
    private List<PermissionVO> children = new ArrayList<>();

    public static PermissionVO from(SysPermission p) {
        PermissionVO vo = new PermissionVO();
        vo.setId(p.getId());
        vo.setParentId(p.getParentId());
        vo.setName(p.getName());
        vo.setCode(p.getCode());
        vo.setType(p.getType());
        vo.setIcon(p.getIcon());
        vo.setPath(p.getPath());
        vo.setComponent(p.getComponent());
        vo.setSort(p.getSort());
        vo.setVisible(p.getVisible());
        return vo;
    }

    /** 平铺列表组装树形结构 */
    public static List<PermissionVO> buildTree(List<SysPermission> list) {
        List<PermissionVO> vos = list.stream().map(PermissionVO::from).toList();
        Map<Long, PermissionVO> map = vos.stream().collect(Collectors.toMap(PermissionVO::getId, v -> v));
        List<PermissionVO> roots = new ArrayList<>();
        for (PermissionVO vo : vos) {
            PermissionVO parent = map.get(vo.getParentId());
            if (parent == null) roots.add(vo);
            else parent.getChildren().add(vo);
        }
        return roots;
    }
}
