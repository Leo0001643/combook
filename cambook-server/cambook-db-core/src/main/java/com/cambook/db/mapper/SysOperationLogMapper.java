package com.cambook.db.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.cambook.db.entity.SysOperationLog;

/**
 * <p>
 * 后台操作日志：记录管理员所有操作行为，用于安全审计 Mapper 接口
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
public interface SysOperationLogMapper extends BaseMapper<SysOperationLog> {

}
