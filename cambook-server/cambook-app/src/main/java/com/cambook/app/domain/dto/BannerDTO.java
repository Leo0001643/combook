package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * Banner 轮播图（Admin）
 *
 * @author CamBook
 */
@Data
@Schema(description = "Banner 请求")
public class BannerDTO {

    @Schema(description = "主键（修改时必填）")
    private Long id;

    @NotBlank(message = "位置标识不能为空")
    @Pattern(regexp = "^[a-z][a-z0-9_]{1,49}$", message = "位置标识只能包含小写字母、数字、下划线")
    @Schema(description = "位置标识，如 home_top", example = "home_top")
    private String position;

    @NotBlank(message = "图片URL不能为空")
    @Pattern(regexp = "^https?://.+$", message = "图片必须为合法URL")
    @Schema(description = "图片 URL")
    private String imageUrl;

    @Size(max = 100, message = "中文标题最多100字")
    @Schema(description = "标题（中文）")
    private String titleZh;

    @Size(max = 100, message = "英文标题最多100字符")
    @Schema(description = "标题（英文）")
    private String titleEn;

    @Size(max = 100, message = "越南文标题最多100字符")
    @Schema(description = "标题（越南文）")
    private String titleVi;

    @Size(max = 100, message = "高棉文标题最多100字符")
    @Schema(description = "标题（高棉文）")
    private String titleKm;

    @NotNull(message = "跳转类型不能为空")
    @Min(value = 0) @Max(value = 2)
    @Schema(description = "跳转类型：0无 1内部路由 2外链")
    private Integer linkType;

    @Schema(description = "跳转目标")
    private String linkValue;

    @Min(value = 0)
    @Schema(description = "排序")
    private Integer sort;

    @Min(value = 0) @Max(value = 1)
    @Schema(description = "状态：1启用 0停用")
    private Integer status;

    @Schema(description = "生效开始时间")
    private LocalDateTime startTime;

    @Schema(description = "生效结束时间")
    private LocalDateTime endTime;
}
