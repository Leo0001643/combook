package com.cambook.db.service.impl;

import com.cambook.db.entity.SysOperationLog;
import com.cambook.db.mapper.SysOperationLogMapper;
import com.cambook.db.service.ISysOperationLogService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 后台操作日志：记录管理员所有操作行为，用于安全审计 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class SysOperationLogServiceImpl extends ServiceImpl<SysOperationLogMapper, SysOperationLog> implements ISysOperationLogService {

}
