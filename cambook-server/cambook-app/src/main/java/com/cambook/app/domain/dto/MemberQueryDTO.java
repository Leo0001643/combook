package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.Data;

/**
 * 会员列表查询（Admin / Merchant）
 *
 * <p>所有过滤条件均由后端处理，避免分页后客户端二次过滤的数据不准问题。
 *
 * @author CamBook
 */
@Data
@Schema(description = "会员查询条件")
public class MemberQueryDTO {

    /**
     * 商户范围隔离（内部字段，不接受外部绑定）：
     * - null  → Admin：查全量
     * - 非null → Merchant 控制器注入，外部参数传入的值会被强制覆盖
     */
    @Schema(hidden = true)
    @com.fasterxml.jackson.annotation.JsonIgnore
    private Long merchantId;

    @Schema(description = "关键词（同时模糊匹配手机号和昵称）")
    private String keyword;

    @Schema(description = "Telegram账号（模糊）")
    private String telegram;

    @Schema(description = "地址（模糊）")
    private String address;

    @Min(value = 1, message = "状态值最小为1") @Max(value = 3, message = "状态值最大为3")
    @Schema(description = "状态：1正常 2封禁 3注销中")
    private Integer status;

    @Schema(description = "性别：1男 2女")
    private Integer gender;

    @Min(value = 0) @Max(value = 4)
    @Schema(description = "会员等级：0普通 1银卡 2金卡 3铂金 4钻石")
    private Integer level;

    @Schema(description = "语言代码，如 zh / km / vi / en")
    private String lang;

    @Schema(description = "注册时间范围起始（UTC 秒级时间戳，含）")
    private Long startDate;

    @Schema(description = "注册时间范围结束（UTC 秒级时间戳，含）")
    private Long endDate;

    @Min(value = 1, message = "页码最小为1")
    @Schema(description = "页码", defaultValue = "1", example = "1")
    private int page = 1;

    @Min(value = 1, message = "每页条数最小为1") @Max(value = 200, message = "每页条数最大200")
    @Schema(description = "每页条数", defaultValue = "20", example = "20")
    private int size = 20;
}
