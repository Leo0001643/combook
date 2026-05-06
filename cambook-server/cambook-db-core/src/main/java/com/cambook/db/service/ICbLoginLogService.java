package com.cambook.db.service;

import com.cambook.db.entity.CbLoginLog;
import com.baomidou.mybatisplus.extension.service.IService;

/**
 * <p>
 * 用户登录日志：记录所有用户登录行为，用于安全审计和异常监控 服务类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
public interface ICbLoginLogService extends IService<CbLoginLog> {

}
