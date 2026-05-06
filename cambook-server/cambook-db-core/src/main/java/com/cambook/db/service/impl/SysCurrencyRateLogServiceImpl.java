package com.cambook.db.service.impl;

import com.cambook.db.entity.SysCurrencyRateLog;
import com.cambook.db.mapper.SysCurrencyRateLogMapper;
import com.cambook.db.service.ISysCurrencyRateLogService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 汇率变动历史：支持查看某币种汇率走势 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class SysCurrencyRateLogServiceImpl extends ServiceImpl<SysCurrencyRateLogMapper, SysCurrencyRateLog> implements ISysCurrencyRateLogService {

}
