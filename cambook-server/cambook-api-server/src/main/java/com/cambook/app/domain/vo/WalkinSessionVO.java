package com.cambook.app.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;
import java.util.List;

/**
 * 散客接待会话 VO
 *
 * @author CamBook
 */
@Data
@Schema(description = "散客接待会话信息")
public class WalkinSessionVO {

    @Schema(description = "接待记录 ID")
    private Long id;

    @Schema(description = "接待编号")
    private String sessionNo;

    @Schema(description = "手环号")
    private String wristbandNo;

    @Schema(description = "客户姓名")
    private String memberName;

    @Schema(description = "客户手机号")
    private String memberMobile;

    @Schema(description = "技师 ID")
    private Long technicianId;

    @Schema(description = "技师姓名")
    private String technicianName;

    @Schema(description = "技师工号")
    private String technicianNo;

    @Schema(description = "技师手机号")
    private String technicianMobile;

    @Schema(description = "接待状态")
    private Integer status;

    @Schema(description = "消费总金额")
    private BigDecimal totalAmount;

    @Schema(description = "实收金额")
    private BigDecimal paidAmount;

    @Schema(description = "签到时间（Unix 秒）")
    private Long checkInTime;

    @Schema(description = "服务开始时间（Unix 秒）")
    private Long serviceStartTime;

    @Schema(description = "结账时间（Unix 秒）")
    private Long checkOutTime;

    @Schema(description = "备注")
    private String remark;

    @Schema(description = "服务项列表")
    private List<WalkinItemVO> orderItems;
}
