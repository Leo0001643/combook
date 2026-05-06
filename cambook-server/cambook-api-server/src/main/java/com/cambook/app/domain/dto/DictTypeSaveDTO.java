package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * 字典类型新增/编辑 DTO
 */
@Data
@Schema(description = "字典类型保存请求")
public class DictTypeSaveDTO {

    @Schema(description = "ID（编辑时必填）")
    private Long id;

    @NotBlank(message = "字典名称不能为空")
    @Schema(description = "字典名称")
    private String dictName;

    @NotBlank(message = "字典类型标识不能为空")
    @Schema(description = "字典类型标识")
    private String dictType;

    @Schema(description = "备注")
    private String remark;

    @Schema(description = "状态：0禁用 1启用")
    private Integer status;
}
