package com.cambook.app.domain.vo;

import com.cambook.dao.entity.SysPosition;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

/**
 * 职位视图
 *
 * @author CamBook
 */
@Data
@Schema(description = "职位信息")
public class PositionVO {

    @Schema(description = "职位 ID")
    private Long id;

    @Schema(description = "所属部门ID")
    private Long deptId;

    @Schema(description = "职位名称")
    private String name;

    @Schema(description = "职位编码")
    private String code;

    @Schema(description = "备注")
    private String remark;

    @Schema(description = "排序")
    private Integer sort;

    @Schema(description = "状态：1启用 0停用")
    private Integer status;

    @Schema(description = "全量权限：1=该职位拥有所有菜单（如总裁），0=按分配")
    private Integer fullAccess;

    @Schema(description = "创建时间")
    private Long createTime;

    public static PositionVO from(SysPosition p) {
        PositionVO vo = new PositionVO();
        vo.setId(p.getId());
        vo.setDeptId(p.getDeptId());
        vo.setName(p.getName());
        vo.setCode(p.getCode());
        vo.setRemark(p.getRemark());
        vo.setSort(p.getSort());
        vo.setStatus(p.getStatus());
        vo.setFullAccess(p.getFullAccess());
        vo.setCreateTime(p.getCreateTime());
        return vo;
    }
}
