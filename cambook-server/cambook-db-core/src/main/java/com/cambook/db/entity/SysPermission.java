package com.cambook.db.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.io.Serializable;

/**
 * <p>
 * 权限菜单表：树形结构，三级（目录/菜单/按钮），实现 RBAC 到按钮级粒度
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("sys_permission")
public class SysPermission implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键，自增
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 父节点 ID；0 表示顶级目录，即根节点
     */
    private Long parentId;

    /**
     * 权限/菜单名称，如 会员管理 / 查看列表
     */
    private String name;

    /**
     * 权限标识（格式 模块:操作，如 member:list / order:delete），按钮级权限必填，目录/菜单可为空
     */
    private String code;

    /**
     * 节点类型：1=目录（仅分组，无路由） 2=菜单（有页面路由） 3=按钮/操作权限（控制接口）
     */
    private Byte type;

    /**
     * 前端路由路径，type=2 时必填，如 /member/list
     */
    private String path;

    /**
     * 前端组件相对路径，type=2 时必填，如 member/MemberList
     */
    private String component;

    /**
     * 菜单图标名或图标 URL，前端展示使用
     */
    private String icon;

    /**
     * 同级节点排序权重，值越小越靠前
     */
    private Integer sort;

    /**
     * 0=管理端 1=商户端
     */
    private Byte portalType;

    /**
     * 是否在侧边菜单中显示：1=显示 0=隐藏（如详情页路由）
     */
    private Byte visible;

    /**
     * 状态：1=启用 0=停用（停用后角色无法使用该权限）
     */
    private Byte status;

    /**
     * 逻辑删除：0=正常 1=已删除
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
