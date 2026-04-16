package com.cambook.dao.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import java.time.LocalDateTime;

/** 职位菜单权限 */
@TableName("sys_position_menu")
public class SysPositionMenu {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long merchantId;
    private Long positionId;
    private String menuKey;
    private LocalDateTime createTime;

    public Long getId() { return id; }
    public void setId(Long v) { this.id = v; }
    public Long getMerchantId() { return merchantId; }
    public void setMerchantId(Long v) { this.merchantId = v; }
    public Long getPositionId() { return positionId; }
    public void setPositionId(Long v) { this.positionId = v; }
    public String getMenuKey() { return menuKey; }
    public void setMenuKey(String v) { this.menuKey = v; }
    public LocalDateTime getCreateTime() { return createTime; }
    public void setCreateTime(LocalDateTime v) { this.createTime = v; }
}
