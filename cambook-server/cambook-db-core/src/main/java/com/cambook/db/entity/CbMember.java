package com.cambook.db.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * <p>
 * 会员表：账号+钱包+等级三合一设计，避免频繁连表
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("cb_member")
public class CbMember implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键，自增
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 会员编号，业务唯一标识，格式 CB+日期+序号，如 CB202604130001
     */
    private String memberNo;

    /**
     * 手机号（国际格式，含国家代码，如 +85512345678），全局唯一，作为登录账号
     */
    private String mobile;

    /**
     * Telegram账号
     */
    private String telegram;

    /**
     * 密码（BCrypt 哈希，预留字段，当前使用短信验证码登录可不填）
     */
    private String password;

    /**
     * 昵称，用户设置的展示名称
     */
    private String nickname;

    /**
     * 头像图片 URL，默认使用系统默认头像
     */
    private String avatar;

    /**
     * 性别：0=未知 1=男 2=女
     */
    private Byte gender;

    /**
     * 生日（yyyy-MM-dd），用于会员营销和生日特权
     */
    private LocalDate birthday;

    /**
     * 真实姓名（实名认证后填写）
     */
    private String realName;

    /**
     * 证件号（护照/身份证，建议加密存储）
     */
    private String idCard;

    /**
     * 首选语言：zh=中文 en=英文 vi=越南文 km=柬埔寨文 ja=日文 ko=韩文
     */
    private String lang;

    /**
     * 会员等级：0=普通 1=银卡 2=金卡 3=钻石
     */
    private Byte level;

    /**
     * 积分余额（消费/活动累积，可用于兑换）
     */
    private Integer points;

    /**
     * 邀请人会员 ID（注册时填写邀请码关联），关联 cb_member.id
     */
    private Long inviterId;

    /**
     * 我的邀请码（随机生成，唯一），用于分享拉新
     */
    private String inviteCode;

    /**
     * 钱包余额（USD，保留两位小数），充值/退款增加，消费减少
     */
    private BigDecimal balance;

    /**
     * 累计充值金额（USD，只增不减，用于等级评定和活动门槛）
     */
    private BigDecimal totalRecharge;

    /**
     * 累计消费金额（USD，只增不减，用于分析用户价值）
     */
    private BigDecimal totalSpend;

    /**
     * 累计完成订单数量（status=6 已完成才计入）
     */
    private Integer orderCount;

    /**
     * 账号状态：1=正常 2=封禁（禁止登录和下单） 3=注销申请中
     */
    private Byte status;

    /**
     * 注册来源：1=APP 2=H5
     */
    private Byte registerSource;

    /**
     * 注册时的 IP 地址，用于反欺诈分析
     */
    private String registerIp;

    /**
     * 注册时间（UTC 秒级时间戳）
     */
    private Long registerTime;

    /**
     * 最后一次登录时间（UTC 秒级时间戳）
     */
    private Long lastLoginTime;

    /**
     * 最后一次登录 IP
     */
    private String lastLoginIp;

    /**
     * 会员地址
     */
    private String address;

    /**
     * 逻辑删除：0=正常 1=已注销删除
     */
    private Byte deleted;

    /**
     * 记录创建时间（同 register_time，由 MyBatis-Plus 自动填充）（UTC 秒级时间戳）
     */
    private Long createTime;

    /**
     * 记录最后修改时间，自动更新（UTC 秒级时间戳）
     */
    private Long updateTime;
}
