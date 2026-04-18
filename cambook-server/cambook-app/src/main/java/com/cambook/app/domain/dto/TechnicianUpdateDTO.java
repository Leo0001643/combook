package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;
import java.util.List;

/**
 * 后台编辑技师 DTO
 *
 * @author CamBook
 */
@Data
@Schema(description = "编辑技师参数")
public class TechnicianUpdateDTO {

    @NotNull
    @Schema(description = "技师 ID")
    private Long id;

    @Schema(description = "真实姓名")
    private String realName;

    @Schema(description = "昵称（展示名）")
    private String nickname;

    @Min(1) @Max(2)
    @Schema(description = "性别：1男 2女")
    private Integer gender;

    @Schema(description = "国籍")
    private String nationality;

    @Schema(description = "服务城市")
    private String serviceCity;

    @Schema(description = "常用语言：zh/en/vi/km")
    private String lang;

    @Schema(description = "中文简介")
    private String introZh;

    @Schema(description = "头像 URL")
    private String avatar;

    @Schema(description = "相册 JSON 数组")
    private String photos;

    @Schema(description = "技能标签（逗号分隔或 JSON 数组）")
    private String skillTags;

    @Schema(description = "可提供的服务类目 ID 列表（对应 cb_service_category.id）")
    private List<Long> serviceItemIds;

    @Schema(description = "佣金比例（0-100）")
    private BigDecimal commissionRate;

    @Schema(description = "身高（cm）")
    private Integer height;

    @Schema(description = "体重（kg）")
    private BigDecimal weight;

    @Schema(description = "年龄")
    private Integer age;

    @Schema(description = "胸围")
    private String bust;

    @Schema(description = "Telegram 账号")
    private String telegram;

    @Schema(description = "展示视频 URL")
    private String videoUrl;

    @Schema(description = "结算方式: 0每笔 1日结 2周结 3月结")
    private Integer settlementMode;

    @Schema(description = "提成类型: 0按比例 1固定金额")
    private Integer commissionType;

    @Schema(description = "按比例提成百分比(%)")
    private BigDecimal commissionRatePct;

    @Schema(description = "固定金额结算币种")
    private String commissionCurrency;

    @Schema(description = "所在省份/籍贯")
    private String province;
}
