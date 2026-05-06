package com.cambook.db.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.io.Serializable;
import java.math.BigDecimal;

/**
 * <p>
 * 商户表：多语言名称/地址，含业务类型和特色功能开关
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("cb_merchant")
public class CbMerchant implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键，自增
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 商户编号，业务唯一标识，格式 M+日期+序号
     */
    private String merchantNo;

    /**
     * 商户端登录手机号（国际格式），全局唯一
     */
    private String mobile;

    /**
     * 登录用户名（字母数字）
     */
    private String username;

    /**
     * 商户端登录密码（BCrypt，可选）
     */
    private String password;

    /**
     * 商户名称（中文），必填
     */
    private String merchantNameZh;

    /**
     * 商户名称（英文）
     */
    private String merchantNameEn;

    /**
     * 商户名称（越南文）
     */
    private String merchantNameVi;

    /**
     * 商户名称（柬埔寨文）
     */
    private String merchantNameKm;

    /**
     * 商户 Logo 图片 URL（独立 Logo，区别于通用图标）
     */
    private String logo;

    /**
     * 商户相册图片 URL 列表（JSON Array）
     */
    private String photos;

    /**
     * 联系人姓名（对接运营的负责人）
     */
    private String contactPerson;

    /**
     * 联系人手机号（运营沟通用，可与登录手机不同）
     */
    private String contactMobile;

    /**
     * 所在省/邦（如 Phnom Penh Province）
     */
    private String province;

    /**
     * 所在城市（如 Phnom Penh），用于城市维度筛选
     */
    private String city;

    /**
     * 详细地址（中文）
     */
    private String addressZh;

    /**
     * 详细地址（英文）
     */
    private String addressEn;

    /**
     * 详细地址（越南文）
     */
    private String addressVi;

    /**
     * 详细地址（柬埔寨文）
     */
    private String addressKm;

    /**
     * 商户地址纬度（高德/Google 地图坐标）
     */
    private BigDecimal lat;

    /**
     * 商户地址经度
     */
    private BigDecimal lng;

    /**
     * 营业时间配置（JSON Array，格式: [{day:1,open:"09:00",close:"22:00"}]）
     */
    private String businessHours;

    /**
     * 旗下在职技师数量（冗余统计，避免实时 count）
     */
    private Integer techCount;

    /**
     * 商户钱包余额（USD，来自平台分成），可申请提现
     */
    private BigDecimal balance;

    /**
     * 平台向商户收取的佣金比例（百分比），如 20.00 表示平台抽 20%
     */
    private BigDecimal commissionRate;

    /**
     * 商户业务类型：1=综合 SPA 2=洗浴中心 3=美容美体 4=足疗
     */
    private Byte businessType;

    /**
     * 营业执照号码
     */
    private String businessLicenseNo;

    /**
     * 营业执照照片URL
     */
    private String businessLicensePic;

    /**
     * 营业范围描述
     */
    private String businessScope;

    /**
     * 营业面积/规模
     */
    private String businessArea;

    /**
     * 特色功能开关（JSON Object），如 {"driver_dispatch":true,"logo_custom":true}，控制商户专属功能
     */
    private String features;

    /**
     * 入驻审核状态：0=待审核 1=审核通过 2=审核拒绝
     */
    private Byte auditStatus;

    /**
     * 拒绝原因（audit_status=2 时填写）
     */
    private String rejectReason;

    /**
     * 账号状态：1=正常 2=停用
     */
    private Byte status;

    /**
     * 逻辑删除：0=正常 1=已删除
     */
    private Byte deleted;

    /**
     * 入驻申请时间（UTC 秒级时间戳）
     */
    private Long createTime;

    /**
     * 最后修改时间（UTC 秒级时间戳）
     */
    private Long updateTime;
}
