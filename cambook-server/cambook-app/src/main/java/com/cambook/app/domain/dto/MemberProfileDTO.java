package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.time.LocalDate;

/**
 * 修改个人资料（App）
 *
 * @author CamBook
 */
@Data
@Schema(description = "修改会员资料")
public class MemberProfileDTO {

    @NotBlank(message = "昵称不能为空")
    @Size(min = 2, max = 20, message = "昵称长度2-20个字符")
    @Schema(description = "昵称")
    private String nickname;

    @Pattern(regexp = "^https?://.+\\.(jpg|jpeg|png|gif|webp)(\\?.*)?$",
             message = "头像必须为合法图片URL")
    @Schema(description = "头像 URL")
    private String avatar;

    @Min(value = 0, message = "性别值不合法") @Max(value = 2, message = "性别值不合法")
    @Schema(description = "性别：0未知 1男 2女")
    private Integer gender;

    @Schema(description = "生日（yyyy-MM-dd）", example = "1995-06-15")
    private LocalDate birthday;
}
