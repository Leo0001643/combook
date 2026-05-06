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
 * 用户服务地址表：支持多地址管理，下单时快照至订单
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("cb_address")
public class CbAddress implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键，自增
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 所属会员 ID，关联 cb_member.id
     */
    private Long memberId;

    /**
     * 地址标签（如 家/公司/酒店/星级酒店），方便快速识别
     */
    private String label;

    /**
     * 收件/服务联系人姓名
     */
    private String contactName;

    /**
     * 联系人手机号（国际格式）
     */
    private String contactPhone;

    /**
     * 省/邦
     */
    private String province;

    /**
     * 市/县
     */
    private String city;

    /**
     * 区/镇
     */
    private String district;

    /**
     * 详细地址（门牌号/楼栋/房间号等）
     */
    private String detail;

    /**
     * 地址纬度（高精度，7位小数约 ±1cm）
     */
    private BigDecimal lat;

    /**
     * 地址经度
     */
    private BigDecimal lng;

    /**
     * 是否默认地址：1=是（同一会员仅允许一个默认地址） 0=否
     */
    private Byte isDefault;

    /**
     * 逻辑删除：0=正常 1=已删除（软删除，历史订单快照不受影响）
     */
    private Byte deleted;

    /**
     * 创建时间（UTC 秒级时间戳）
     */
    private Long createTime;

    /**
     * 最后修改时间（UTC 秒级时间戳）
     */
    private Long updateTime;
}
