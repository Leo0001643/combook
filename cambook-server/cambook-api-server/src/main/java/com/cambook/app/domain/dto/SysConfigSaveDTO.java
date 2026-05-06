package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * 系统参数新增/编辑 DTO
 */
@Data
@Schema(description = "系统参数保存请求")
public class SysConfigSaveDTO {

    @Schema(description = "ID（编辑时必填）")
    private Long id;

    @NotBlank(message = "参数名称不能为空")
    @Schema(description = "参数名称")
    private String configName;

    @NotBlank(message = "参数键名不能为空")
    @Schema(description = "参数键名")
    private String configKey;

    @NotBlank(message = "参数值不能为空")
    @Schema(description = "参数值")
    private String configValue;

    @Schema(description = "参数分组")
    private String configGroup = "custom";

    @Schema(description = "备注")
    private String remark;
}
