package com.cambook.db.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.cambook.db.entity.CbLoginLog;

/**
 * <p>
 * 用户登录日志：记录所有用户登录行为，用于安全审计和异常监控 Mapper 接口
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
public interface CbLoginLogMapper extends BaseMapper<CbLoginLog> {

}
