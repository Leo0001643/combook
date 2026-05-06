package com.cambook.app.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

/**
 * 商户登录用户信息 VO
 *
 * @author CamBook
 */
@Data
@Schema(description = "当前登录商户用户信息")
public class MerchantInfoVO {

    @Schema(description = "手机号")
    private String mobile;

    @Schema(description = "登录账号")
    private String username;

    @Schema(description = "真实姓名")
    private String realName;

    @Schema(description = "职位名称")
    private String positionName;

    @Schema(description = "部门名称")
    private String deptName;

    @Schema(description = "是否为员工账号")
    private boolean staff;
}
