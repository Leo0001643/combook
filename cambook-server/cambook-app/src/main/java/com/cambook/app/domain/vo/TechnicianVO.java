package com.cambook.app.domain.vo;

import com.cambook.dao.entity.CbTechnician;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;
import java.util.Collections;
import java.util.List;

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

    @Schema(description = "常用语言")
    private String lang;

    @Schema(description = "中文简介")
    private String introZh;

    @Schema(description = "年龄")
    private Integer age;

    @Schema(description = "身高(cm)")
    private Integer height;

    @Schema(description = "体重(kg)")
    private BigDecimal weight;

    @Schema(description = "罩杯")
    private String bust;

    @Schema(description = "籍贯/所在省份")
    private String province;

    @Schema(description = "展示视频 URL")
    private String videoUrl;

    @Schema(description = "技师分成比例(%)")
    private BigDecimal commissionRate;

    @Schema(description = "结算方式: 0每笔 1日结 2周结 3月结")
    private Integer settlementMode;

    @Schema(description = "提成类型: 0按比例 1固定金额")
    private Integer commissionType;

    @Schema(description = "按比例提成百分比(%)")
    private BigDecimal commissionRatePct;

    @Schema(description = "固定金额结算币种")
    private String commissionCurrency;

    @Schema(description = "技能标签（JSON）")
    private String skillTags;

    @Schema(description = "可提供的服务类目 ID 列表")
    private List<Long> serviceItemIds;

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
        vo.setLang(t.getLang());
        vo.setIntroZh(t.getIntroZh());
        vo.setAge(t.getAge());
        vo.setHeight(t.getHeight());
        vo.setWeight(t.getWeight());
        vo.setBust(t.getBust());
        vo.setProvince(t.getProvince());
        vo.setVideoUrl(t.getVideoUrl());
        vo.setCommissionRate(t.getCommissionRate());
        vo.setSettlementMode(t.getSettlementMode());
        vo.setCommissionType(t.getCommissionType());
        vo.setCommissionRatePct(t.getCommissionRatePct());
        vo.setCommissionCurrency(t.getCommissionCurrency());
        vo.setSkillTags(t.getSkillTags());
        vo.setServiceItemIds(parseIds(t.getServiceItemIds()));
        vo.setIsFeatured(t.getIsFeatured());
        vo.setStatus(t.getStatus());
        return vo;
    }

    /** 将 JSON 数组字符串 "[1,2,3]" 解析为 Long 列表，容错处理。 */
    private static List<Long> parseIds(String json) {
        if (json == null || json.isBlank()) return Collections.emptyList();
        try {
            json = json.trim();
            if (!json.startsWith("[")) return Collections.emptyList();
            String inner = json.substring(1, json.length() - 1).trim();
            if (inner.isEmpty()) return Collections.emptyList();
            List<Long> result = new java.util.ArrayList<>();
            for (String part : inner.split(",")) {
                String p = part.trim();
                if (!p.isEmpty()) result.add(Long.parseLong(p));
            }
            return result;
        } catch (Exception e) {
            return Collections.emptyList();
        }
    }
}
