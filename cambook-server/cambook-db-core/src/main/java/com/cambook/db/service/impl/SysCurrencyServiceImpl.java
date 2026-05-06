package com.cambook.db.service.impl;

import com.cambook.db.entity.SysCurrency;
import com.cambook.db.mapper.SysCurrencyMapper;
import com.cambook.db.service.ISysCurrencyService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 币种注册表：平台支持的所有结算货币及实时汇率 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class SysCurrencyServiceImpl extends ServiceImpl<SysCurrencyMapper, SysCurrency> implements ISysCurrencyService {

}
