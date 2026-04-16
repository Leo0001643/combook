package com.cambook.dao.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.cambook.dao.entity.base.BaseEntity;
import io.swagger.v3.oas.annotations.media.Schema;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 会员表
 *
 * <p>账号信息、钱包余额、等级、邀请关系合并在此表，避免多表 JOIN。
 *
 * @author CamBook
 */
@TableName("cb_member")
@Schema(description = "会员信息")
public class CbMember extends BaseEntity {

    private String memberNo;
    private String mobile;
    private String telegram;
    private String password;
    private String nickname;
    private String avatar;
    private Integer gender;
    private LocalDate birthday;
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
    private LocalDateTime registerTime;
    private LocalDateTime lastLoginTime;
    private String lastLoginIp;
    private String address;

    public String getMemberNo()             { return memberNo; }
    public String getMobile()               { return mobile; }
    public String getTelegram()             { return telegram; }
    public String getPassword()             { return password; }
    public String getNickname()             { return nickname; }
    public String getAvatar()               { return avatar; }
    public Integer getGender()              { return gender; }
    public LocalDate getBirthday()          { return birthday; }
    public String getRealName()             { return realName; }
    public String getIdCard()               { return idCard; }
    public String getLang()                 { return lang; }
    public Integer getLevel()               { return level; }
    public Integer getPoints()              { return points; }
    public Long getInviterId()              { return inviterId; }
    public String getInviteCode()           { return inviteCode; }
    public BigDecimal getBalance()          { return balance; }
    public BigDecimal getTotalRecharge()    { return totalRecharge; }
    public BigDecimal getTotalSpend()       { return totalSpend; }
    public Integer getOrderCount()          { return orderCount; }
    public Integer getStatus()              { return status; }
    public Integer getRegisterSource()      { return registerSource; }
    public String getRegisterIp()           { return registerIp; }
    public LocalDateTime getRegisterTime()  { return registerTime; }
    public LocalDateTime getLastLoginTime() { return lastLoginTime; }
    public String getLastLoginIp()          { return lastLoginIp; }
    public String getAddress()              { return address; }

    public void setMemberNo(String memberNo)                 { this.memberNo = memberNo; }
    public void setMobile(String mobile)                     { this.mobile = mobile; }
    public void setTelegram(String telegram)                 { this.telegram = telegram; }
    public void setPassword(String password)                 { this.password = password; }
    public void setNickname(String nickname)                 { this.nickname = nickname; }
    public void setAvatar(String avatar)                     { this.avatar = avatar; }
    public void setGender(Integer gender)                    { this.gender = gender; }
    public void setBirthday(LocalDate birthday)              { this.birthday = birthday; }
    public void setRealName(String realName)                 { this.realName = realName; }
    public void setIdCard(String idCard)                     { this.idCard = idCard; }
    public void setLang(String lang)                         { this.lang = lang; }
    public void setLevel(Integer level)                      { this.level = level; }
    public void setPoints(Integer points)                    { this.points = points; }
    public void setInviterId(Long inviterId)                 { this.inviterId = inviterId; }
    public void setInviteCode(String inviteCode)             { this.inviteCode = inviteCode; }
    public void setBalance(BigDecimal balance)               { this.balance = balance; }
    public void setTotalRecharge(BigDecimal totalRecharge)   { this.totalRecharge = totalRecharge; }
    public void setTotalSpend(BigDecimal totalSpend)         { this.totalSpend = totalSpend; }
    public void setOrderCount(Integer orderCount)            { this.orderCount = orderCount; }
    public void setStatus(Integer status)                    { this.status = status; }
    public void setRegisterSource(Integer registerSource)    { this.registerSource = registerSource; }
    public void setRegisterIp(String registerIp)             { this.registerIp = registerIp; }
    public void setRegisterTime(LocalDateTime registerTime)  { this.registerTime = registerTime; }
    public void setLastLoginTime(LocalDateTime lastLoginTime){ this.lastLoginTime = lastLoginTime; }
    public void setLastLoginIp(String lastLoginIp)           { this.lastLoginIp = lastLoginIp; }
    public void setAddress(String address)                   { this.address = address; }
}
