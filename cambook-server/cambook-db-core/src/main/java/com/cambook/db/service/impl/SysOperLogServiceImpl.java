package com.cambook.db.service.impl;

import com.cambook.db.entity.SysOperLog;
import com.cambook.db.mapper.SysOperLogMapper;
import com.cambook.db.service.ISysOperLogService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 操作日志记录 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class SysOperLogServiceImpl extends ServiceImpl<SysOperLogMapper, SysOperLog> implements ISysOperLogService {

}
