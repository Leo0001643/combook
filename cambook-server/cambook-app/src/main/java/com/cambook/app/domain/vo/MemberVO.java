package com.cambook.app.domain.vo;

import com.cambook.dao.entity.CbMember;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 会员信息视图
 *
 * <p>字段命名以前端约定为准（createdAt / totalAmount / orderCount），
 * 避免前后端字段名不一致导致的数据展示 Bug。
 *
 * @author CamBook
 */
@Data
@Schema(description = "会员信息")
public class MemberVO {

    @Schema(description = "会员 ID")
    private Long id;

    @Schema(description = "会员编号")
    private String memberNo;

    @Schema(description = "手机号（脱敏）")
    private String mobile;

    @Schema(description = "Telegram账号")
    private String telegram;

    @Schema(description = "昵称")
    private String nickname;

    @Schema(description = "头像")
    private String avatar;

    @Schema(description = "性别：0未知 1男 2女")
    private Integer gender;

    @Schema(description = "首选语言")
    private String lang;

    @Schema(description = "会员等级：0普通 1银卡 2金卡 3铂金 4钻石")
    private Integer level;

    @Schema(description = "积分")
    private Integer points;

    @Schema(description = "钱包余额（USD）")
    private BigDecimal balance;

    @Schema(description = "累计消费金额（USD）")
    private BigDecimal totalAmount;

    @Schema(description = "订单总数")
    private Integer orderCount;

    @Schema(description = "状态：1正常 2封禁 3注销中")
    private Integer status;

    @Schema(description = "会员地址")
    private String address;

    @Schema(description = "注册时间")
    private LocalDateTime createdAt;

    public static MemberVO from(CbMember m) {
        MemberVO vo = new MemberVO();
        vo.setId(m.getId());
        vo.setMemberNo(m.getMemberNo());
        vo.setMobile(maskMobile(m.getMobile()));
        vo.setTelegram(m.getTelegram());
        vo.setNickname(m.getNickname());
        vo.setAvatar(m.getAvatar());
        vo.setGender(m.getGender());
        vo.setLang(m.getLang());
        vo.setLevel(m.getLevel());
        vo.setPoints(m.getPoints());
        vo.setBalance(m.getBalance());
        vo.setTotalAmount(m.getTotalSpend());
        vo.setOrderCount(m.getOrderCount());
        vo.setStatus(m.getStatus());
        vo.setAddress(m.getAddress());
        vo.setCreatedAt(m.getRegisterTime());
        return vo;
    }

    private static String maskMobile(String mobile) {
        if (mobile == null || mobile.length() < 7) return mobile;
        return mobile.substring(0, mobile.length() - 8) + "****" + mobile.substring(mobile.length() - 4);
    }
}
