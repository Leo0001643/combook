package com.cambook.db.service.impl;

import com.cambook.db.entity.CbLoginLog;
import com.cambook.db.mapper.CbLoginLogMapper;
import com.cambook.db.service.ICbLoginLogService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 用户登录日志：记录所有用户登录行为，用于安全审计和异常监控 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class CbLoginLogServiceImpl extends ServiceImpl<CbLoginLogMapper, CbLoginLog> implements ICbLoginLogService {

}
