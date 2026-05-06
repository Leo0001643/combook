package com.cambook.db.service.impl;

import com.cambook.db.entity.SysConfig;
import com.cambook.db.mapper.SysConfigMapper;
import com.cambook.db.service.ISysConfigService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 系统配置表：KV 格式，支持分组，适用于动态运营参数配置 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class SysConfigServiceImpl extends ServiceImpl<SysConfigMapper, SysConfig> implements ISysConfigService {

}
