package com.cambook.app.domain.vo;

import com.cambook.dao.entity.CbTechnician;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;

/**
 * 技师信息视图
 *
 * @author CamBook
 */
@Data
@Schema(description = "技师信息")
public class TechnicianVO {

    @Schema(description = "技师 ID")
    private Long id;

    @Schema(description = "技师编号")
    private String techNo;

    @Schema(description = "真实姓名")
    private String realName;

    @Schema(description = "手机号")
    private String mobile;

    @Schema(description = "Telegram账号")
    private String telegram;

    @Schema(description = "昵称")
    private String nickname;

    @Schema(description = "头像")
    private String avatar;

    @Schema(description = "相册（JSON）")
    private String photos;

    @Schema(description = "性别：1男 2女")
    private Integer gender;

    @Schema(description = "国籍")
    private String nationality;

    @Schema(description = "服务城市")
    private String serviceCity;

    @Schema(description = "综合评分")
    private BigDecimal rating;

    @Schema(description = "评价数量")
    private Integer reviewCount;

    @Schema(description = "完成订单数")
    private Integer orderCount;

    @Schema(description = "好评率(%)")
    private BigDecimal goodReviewRate;

    @Schema(description = "在线状态：0离线 1在线 2服务中")
    private Integer onlineStatus;

    @Schema(description = "审核状态：0待审 1通过 2拒绝")
    private Integer auditStatus;

    @Schema(description = "拒绝原因")
    private String rejectReason;

    @Schema(description = "技能标签（JSON）")
    private String skillTags;

    @Schema(description = "是否推荐")
    private Integer isFeatured;

    @Schema(description = "账号状态：0停用 1正常")
    private Integer status;

    /** 归属商户 ID（用于服务端行级安全校验 & 前端展示） */
    private Long merchantId;

    @Schema(description = "归属商户名称（管理端列表展示）")
    private String merchantName;

    public static TechnicianVO from(CbTechnician t) {
        TechnicianVO vo = new TechnicianVO();
        vo.setId(t.getId());
        vo.setMerchantId(t.getMerchantId());
        vo.setTechNo(t.getTechNo());
        vo.setRealName(t.getRealName());
        vo.setMobile(t.getMobile());
        vo.setTelegram(t.getTelegram());
        vo.setNickname(t.getNickname());
        vo.setAvatar(t.getAvatar());
        vo.setPhotos(t.getPhotos());
        vo.setGender(t.getGender());
        vo.setNationality(t.getNationality());
        vo.setServiceCity(t.getServiceCity());
        vo.setRating(t.getRating());
        vo.setReviewCount(t.getReviewCount());
        vo.setOrderCount(t.getOrderCount());
        vo.setGoodReviewRate(t.getGoodReviewRate());
        vo.setOnlineStatus(t.getOnlineStatus());
        vo.setAuditStatus(t.getAuditStatus());
        vo.setRejectReason(t.getRejectReason());
        vo.setSkillTags(t.getSkillTags());
        vo.setIsFeatured(t.getIsFeatured());
        vo.setStatus(t.getStatus());
        return vo;
    }
}
