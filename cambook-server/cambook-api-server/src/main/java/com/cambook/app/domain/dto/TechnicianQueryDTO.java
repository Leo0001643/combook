package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Pattern;
import lombok.Data;

/**
 * 技师列表查询（Admin）
 *
 * @author CamBook
 */
@Data
@Schema(description = "技师查询条件")
public class TechnicianQueryDTO {

    /**
     * 商户范围隔离（内部字段，不接受外部绑定）：
     * - null  → Admin：查全量
     * - 非null → Merchant 控制器注入，外部参数传入的值会被强制覆盖
     */
    @Schema(hidden = true)
    @com.fasterxml.jackson.annotation.JsonIgnore
    private Long merchantId;

    @Schema(description = "关键词（昵称/真实姓名/手机号模糊搜索）")
    private String keyword;

    @Schema(description = "手机号（精确）")
    private String mobile;

    @Schema(description = "Telegram账号（模糊）")
    private String telegram;

    @Schema(description = "联系方式关键词（contactType 为空则全字段搜索）")
    private String contactValue;

    @Schema(description = "联系方式类型：telegram（目前仅支持 telegram）")
    private String contactType;

    @Schema(description = "真实姓名（模糊）")
    private String realName;

    @Min(value = 0) @Max(value = 2)
    @Schema(description = "审核状态：0待审 1通过 2拒绝")
    private Integer auditStatus;

    @Min(value = 0) @Max(value = 2)
    @Schema(description = "在线状态（业务）：0离线 1在线 2服务中")
    private Integer onlineStatus;

    @Min(value = 0) @Max(value = 1)
    @Schema(description = "APP登录状态：0=未登录 1=已登录（有活跃Token）")
    private Integer loginStatus;

    @Schema(description = "所在城市")
    private String serviceCity;

    @Min(value = 1) @Max(value = 2)
    @Schema(description = "性别：1男 2女")
    private Integer gender;

    @Schema(description = "国籍（精确匹配）")
    private String nationality;

    @Min(1) @Schema(description = "页码", defaultValue = "1")
    private int page = 1;

    @Min(1) @Max(100) @Schema(description = "每页条数", defaultValue = "20")
    private int size = 20;
}
