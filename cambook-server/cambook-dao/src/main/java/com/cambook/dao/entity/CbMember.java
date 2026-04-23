package com.cambook.dao.entity;

import lombok.Getter;
import lombok.Setter;

import com.baomidou.mybatisplus.annotation.TableName;
import com.cambook.dao.entity.base.BaseEntity;
import io.swagger.v3.oas.annotations.media.Schema;

import java.math.BigDecimal;

/**
 * 会员表
 *
 * <p>账号信息、钱包余额、等级、邀请关系合并在此表，避免多表 JOIN。
 *
 * @author CamBook
 */
@TableName("cb_member")
@Schema(description = "会员信息")
@Getter
@Setter
public class CbMember extends BaseEntity {

    private String memberNo;
    private String mobile;
    private String telegram;
    private String password;
    private String nickname;
    private String avatar;
    private Integer gender;
    private String birthday;
    private String realName;
    private String idCard;
    private String lang;
    private Integer level;
    private Integer points;
    private Long inviterId;
    private String inviteCode;
    private BigDecimal balance;
    private BigDecimal totalRecharge;
    private BigDecimal totalSpend;
    private Integer orderCount;
    private Integer status;
    private Integer registerSource;
    private String registerIp;
    private Long registerTime;
    private Long lastLoginTime;
    private String lastLoginIp;
    private String address;

}
