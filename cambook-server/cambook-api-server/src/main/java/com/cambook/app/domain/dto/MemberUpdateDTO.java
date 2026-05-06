package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * 后台编辑会员 DTO
 *
 * @author CamBook
 */
@Data
@Schema(description = "编辑会员参数")
public class MemberUpdateDTO {

    @NotNull
    @Schema(description = "会员 ID")
    private Long id;

    @Schema(description = "昵称")
    private String nickname;

    @Schema(description = "头像 URL")
    private String avatar;

    @Min(0) @Max(2)
    @Schema(description = "性别：0未知 1男 2女")
    private Integer gender;

    @Schema(description = "Telegram 账号")
    private String telegram;

    @Schema(description = "地址")
    private String address;
}
