package com.cambook.dao.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import java.time.LocalDateTime;

/** 部门菜单权限 */
@TableName("sys_dept_menu")
public class SysDeptMenu {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long merchantId;
    private Long deptId;
    private String menuKey;
    private LocalDateTime createTime;

    public Long getId() { return id; }
    public void setId(Long v) { this.id = v; }
    public Long getMerchantId() { return merchantId; }
    public void setMerchantId(Long v) { this.merchantId = v; }
    public Long getDeptId() { return deptId; }
    public void setDeptId(Long v) { this.deptId = v; }
    public String getMenuKey() { return menuKey; }
    public void setMenuKey(String v) { this.menuKey = v; }
    public LocalDateTime getCreateTime() { return createTime; }
    public void setCreateTime(LocalDateTime v) { this.createTime = v; }
}
