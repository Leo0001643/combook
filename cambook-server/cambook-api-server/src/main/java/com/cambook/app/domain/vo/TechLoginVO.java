package com.cambook.app.domain.vo;

import com.cambook.db.entity.CbTechnician;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;

/**
 * 技师端登录响应
 *
 * @author CamBook
 */
@Data
@Schema(description = "技师端登录响应")
public class TechLoginVO {

    // ── 认证凭据 ──────────────────────────────────────────────────────────────

    @Schema(description = "JWT Token")
    private String token;

    @Schema(description = "Token 过期时间（Unix 秒）")
    private long expiresAt;

    // ── 基本信息 ──────────────────────────────────────────────────────────────

    @Schema(description = "技师 ID")
    private Long techId;

    @Schema(description = "技师编号，格式 T+日期+序号", example = "T20240001")
    private String techNo;

    @Schema(description = "真实姓名")
    private String realName;

    @Schema(description = "昵称（展示用）")
    private String nickname;

    @Schema(description = "头像 URL")
    private String avatar;

    @Schema(description = "手机号（国际格式）")
    private String mobile;

    // ── 账号状态 ──────────────────────────────────────────────────────────────

    @Schema(description = "账号状态：1=正常 2=停用")
    private Byte status;

    @Schema(description = "审核状态：0=待审核 1=通过 2=拒绝")
    private Byte auditStatus;

    @Schema(description = "在线状态：0=离线 1=在线 2=服务中")
    private Byte onlineStatus;

    // ── 商户归属 ──────────────────────────────────────────────────────────────

    @Schema(description = "所属商户 ID")
    private Long merchantId;

    // ── 收益概况 ──────────────────────────────────────────────────────────────

    @Schema(description = "可提现余额")
    private BigDecimal balance;

    @Schema(description = "累计总收入")
    private BigDecimal totalIncome;

    @Schema(description = "评分（1-5）")
    private BigDecimal rating;

    @Schema(description = "完成订单数")
    private Integer orderCount;


    public static TechLoginVO of(String token, long expiresAt, CbTechnician tech) {
        TechLoginVO vo = new TechLoginVO();
        vo.setToken(token);
        vo.setExpiresAt(expiresAt);
        vo.setTechId(tech.getId());
        vo.setTechNo(tech.getTechNo());
        vo.setRealName(tech.getRealName());
        vo.setNickname(tech.getNickname());
        vo.setAvatar(tech.getAvatar());
        vo.setMobile(tech.getMobile());
        vo.setStatus(tech.getStatus());
        vo.setAuditStatus(tech.getAuditStatus());
        vo.setOnlineStatus(tech.getOnlineStatus());
        vo.setMerchantId(tech.getMerchantId());
        vo.setBalance(tech.getBalance());
        vo.setTotalIncome(tech.getTotalIncome());
        vo.setRating(tech.getRating());
        vo.setOrderCount(tech.getOrderCount());
        return vo;
    }
}
