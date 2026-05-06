package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * 员工新增/编辑 DTO
 */
@Data
@Schema(description = "员工保存请求")
public class StaffSaveDTO {

    @Schema(description = "ID（编辑时必填）")
    private Long id;

    @NotBlank(message = "用户名不能为空")
    @Schema(description = "用户名")
    private String username;

    @Schema(description = "密码（新增时必填；编辑时不填则不修改）")
    private String password;

    @Schema(description = "真实姓名")
    private String realName;

    @Schema(description = "手机号")
    private String mobile;

    @Schema(description = "Telegram账号")
    private String telegram;

    @Schema(description = "邮箱")
    private String email;

    @Schema(description = "部门ID")
    private Long deptId;

    @Schema(description = "职位ID")
    private Long positionId;

    @Schema(description = "备注")
    private String remark;

    @Schema(description = "状态：0禁用 1启用")
    private Integer status;
}
