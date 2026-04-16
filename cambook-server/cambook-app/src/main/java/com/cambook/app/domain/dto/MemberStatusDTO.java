package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * 修改会员状态（Admin）
 *
 * @author CamBook
 */
@Data
@Schema(description = "修改会员状态")
public class MemberStatusDTO {

    @NotNull(message = "状态不能为空")
    @Min(value = 1, message = "状态值不合法") @Max(value = 3, message = "状态值不合法")
    @Schema(description = "状态：1正常 2封禁 3注销中")
    private Integer status;

    @Schema(description = "备注原因（封禁时填写）")
    private String reason;
}
