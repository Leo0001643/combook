package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * 字典数据新增/编辑 DTO
 */
@Data
@Schema(description = "字典数据保存请求")
public class DictDataSaveDTO {

    @Schema(description = "ID（编辑时必填）")
    private Long id;

    @NotBlank(message = "字典类型不能为空")
    @Schema(description = "字典类型标识")
    private String dictType;

    @NotBlank(message = "中文标签不能为空")
    @Schema(description = "中文标签")
    private String labelZh;

    @NotBlank(message = "字典值不能为空")
    @Schema(description = "字典值")
    private String dictValue;

    @Schema(description = "英文标签")
    private String labelEn;

    @Schema(description = "越南语标签")
    private String labelVi;

    @Schema(description = "高棉语标签")
    private String labelKm;

    @Schema(description = "排序值")
    private Integer sort = 0;

    @Schema(description = "备注")
    private String remark;

    @Schema(description = "状态：0禁用 1启用")
    private Integer status;
}
