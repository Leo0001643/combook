package com.cambook.dao.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import java.time.LocalDateTime;

/** 员工菜单权限（个人覆盖） */
@TableName("sys_staff_menu")
public class SysStaffMenu {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long merchantId;
    private Long staffId;
    private String menuKey;
    private LocalDateTime createTime;

    public Long getId() { return id; }
    public void setId(Long v) { this.id = v; }
    public Long getMerchantId() { return merchantId; }
    public void setMerchantId(Long v) { this.merchantId = v; }
    public Long getStaffId() { return staffId; }
    public void setStaffId(Long v) { this.staffId = v; }
    public String getMenuKey() { return menuKey; }
    public void setMenuKey(String v) { this.menuKey = v; }
    public LocalDateTime getCreateTime() { return createTime; }
    public void setCreateTime(LocalDateTime v) { this.createTime = v; }
}
