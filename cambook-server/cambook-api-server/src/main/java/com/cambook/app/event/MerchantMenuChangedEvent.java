package com.cambook.app.event;

import org.springframework.context.ApplicationEvent;

/**
 * 商户端菜单变更事件
 *
 * <p>当超级管理员对 portal_type=1 的 sys_permission 执行新增/修改/删除时发布，
 * {@link com.cambook.app.service.merchant.impl.MerchantMenuServiceImpl} 监听并主动失效 Redis 缓存。
 *
 * <p>设计遵循 OCP：发布方（PermissionService）只发事件，无需依赖消费方。
 *
 * @author CamBook
 */
public class MerchantMenuChangedEvent extends ApplicationEvent {

    public MerchantMenuChangedEvent(Object source) {
        super(source);
    }
}
