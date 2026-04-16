package com.cambook.dao.entity;

import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.cambook.dao.entity.base.BaseEntity;

/**
 * 商户员工表
 *
 * @author CamBook
 */
@TableName("cb_merchant_staff")
public class CbMerchantStaff extends BaseEntity {

    private Long   merchantId;
    /** 所属部门ID */
    private Long   deptId;
    /** 所属职位ID */
    private Long   positionId;
    private String username;
    private String password;
    private String realName;
    private String mobile;
    private String telegram;
    private String email;
    private String avatar;
    private String roleName;
    private String perms;
    private Integer status;
    private String remark;

    @TableLogic
    @TableField("deleted")
    private Integer deleted;

    public Long    getMerchantId()             { return merchantId; }
    public void    setMerchantId(Long v)       { this.merchantId = v; }

    public Long    getDeptId()                 { return deptId; }
    public void    setDeptId(Long v)           { this.deptId = v; }

    public Long    getPositionId()             { return positionId; }
    public void    setPositionId(Long v)       { this.positionId = v; }

    public String  getUsername()               { return username; }
    public void    setUsername(String v)       { this.username = v; }

    public String  getPassword()               { return password; }
    public void    setPassword(String v)       { this.password = v; }

    public String  getRealName()               { return realName; }
    public void    setRealName(String v)       { this.realName = v; }

    public String  getMobile()                 { return mobile; }
    public void    setMobile(String v)         { this.mobile = v; }

    public String  getTelegram()               { return telegram; }
    public void    setTelegram(String v)       { this.telegram = v; }

    public String  getEmail()                  { return email; }
    public void    setEmail(String v)          { this.email = v; }

    public String  getAvatar()                 { return avatar; }
    public void    setAvatar(String v)         { this.avatar = v; }

    public String  getRoleName()               { return roleName; }
    public void    setRoleName(String v)       { this.roleName = v; }

    public String  getPerms()                  { return perms; }
    public void    setPerms(String v)          { this.perms = v; }

    public Integer getStatus()                 { return status; }
    public void    setStatus(Integer v)        { this.status = v; }

    public String  getRemark()                 { return remark; }
    public void    setRemark(String v)         { this.remark = v; }

    public Integer getDeleted()                { return deleted; }
    public void    setDeleted(Integer v)       { this.deleted = v; }
}
