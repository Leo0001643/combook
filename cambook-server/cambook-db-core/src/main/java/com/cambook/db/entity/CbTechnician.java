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
 * 技师表：包含认证资料/多语言简介/服务能力/收入统计，合并设计避免连表
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("cb_technician")
public class CbTechnician implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键，自增
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 技师编号，业务唯一标识，格式 T+日期+序号
     */
    private String techNo;

    /**
     * 关联会员 ID（若技师同时是会员则关联，否则为空），关联 cb_member.id
     */
    private Long memberId;

    /**
     * 手机号（国际格式），作为技师端登录账号
     */
    private String mobile;

    /**
     * Telegram账号
     */
    private String telegram;

    /**
     * 微信号
     */
    private String wechat;

    /**
     * Facebook账号
     */
    private String facebook;

    /**
     * 技师端登录密码（BCrypt，预留字段）
     */
    private String password;

    /**
     * 真实姓名（与证件一致，必填）
     */
    private String realName;

    /**
     * 展示昵称（技师对外展示的名称）
     */
    private String nickname;

    /**
     * 头像图片 URL
     */
    private String avatar;

    /**
     * 相册图片 URL 列表（JSON Array），展示在技师详情页
     */
    private String photos;

    /**
     * 展示视频 URL
     */
    private String videoUrl;

    /**
     * 性别：1=男 2=女（服务项目常有性别要求）
     */
    private Byte gender;

    /**
     * 国籍
     */
    private String nationality;

    /**
     * 生日（yyyy-MM-dd）
     */
    private LocalDate birthday;

    /**
     * 证件号（护照/身份证，建议加密存储）
     */
    private String idCard;

    /**
     * 证件正面照片 URL（审核用）
     */
    private String idCardFront;

    /**
     * 证件背面照片 URL（审核用）
     */
    private String idCardBack;

    /**
     * 技师首选语言，同 cb_member.lang 定义
     */
    private String lang;

    /**
     * 个人简介（中文版）
     */
    private String introZh;

    /**
     * 个人简介（英文版）
     */
    private String introEn;

    /**
     * 个人简介（越南文版）
     */
    private String introVi;

    /**
     * 个人简介（柬埔寨文版）
     */
    private String introKm;

    /**
     * 服务城市，用于按城市筛选技师
     */
    private String serviceCity;

    /**
     * 当前位置纬度（GPS 实时定位，精度约 ±1cm）
     */
    private BigDecimal lat;

    /**
     * 当前位置经度（GPS 实时定位，精度约 ±1cm）
     */
    private BigDecimal lng;

    /**
     * 综合评分（1.00-5.00），由历史评价加权计算
     */
    private BigDecimal rating;

    /**
     * 累计收到的评价数量
     */
    private Integer reviewCount;

    /**
     * 累计完成订单数量
     */
    private Integer orderCount;

    /**
     * 好评率（百分比，如 98.50 表示 98.5%）
     */
    private BigDecimal goodReviewRate;

    /**
     * 钱包余额（USD），接单收入累积，可申请提现
     */
    private BigDecimal balance;

    /**
     * 累计总收入（USD，只增不减）
     */
    private BigDecimal totalIncome;

    /**
     * 入驻审核状态：0=待审核 1=审核通过 2=审核拒绝
     */
    private Byte auditStatus;

    /**
     * 审核拒绝原因（audit_status=2 时填写）
     */
    private String rejectReason;

    /**
     * 在线状态：0=离线 1=在线待单 2=服务中（不可接新单）
     */
    private Byte onlineStatus;

    /**
     * 所属商户 ID（关联 cb_merchant.id），独立技师此字段为空
     */
    private Long merchantId;

    /**
     * 技师分成比例（百分比），如 70.00 表示技师得 70%，平台得 30%
     */
    private BigDecimal commissionRate;

    /**
     * 技能标签 ID 列表（JSON Array，关联 cb_tag.id），如 [1,3,5]
     */
    private String skillTags;

    /**
     * 可提供服务类目ID列表(JSON)
     */
    private String serviceItemIds;

    /**
     * 身高（cm）
     */
    private Short height;

    /**
     * 体重（kg）
     */
    private BigDecimal weight;

    /**
     * 年龄
     */
    private Byte age;

    /**
     * 罩杯（A/B/C/D/E/F/G）
     */
    private String bust;

    /**
     * 所在省份
     */
    private String province;

    /**
     * 是否首页推荐：1=是（精选技师） 0=否
     */
    private Byte isFeatured;

    /**
     * 账号状态：1=正常 2=停用（被平台停用，无法接单）
     */
    private Byte status;

    /**
     * 逻辑删除：0=正常 1=已删除
     */
    private Byte deleted;

    /**
     * 申请入驻时间（UTC 秒级时间戳）
     */
    private Long createTime;

    /**
     * 最后修改时间（UTC 秒级时间戳）
     */
    private Long updateTime;

    /**
     * 结算方式：0=每笔结算 1=日结 2=周结 3=月结
     */
    private Byte settlementMode;

    /**
     * 提成类型：0=按比例(%) 1=固定金额/单
     */
    private Byte commissionType;

    /**
     * 按比例提成百分比(%)
     */
    private BigDecimal commissionRatePct;

    /**
     * 固定金额类型时的结算币种
     */
    private String commissionCurrency;
}
