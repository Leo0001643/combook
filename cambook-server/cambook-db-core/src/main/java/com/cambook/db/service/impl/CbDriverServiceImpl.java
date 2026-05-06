package com.cambook.db.service.impl;

import com.cambook.db.entity.CbDriver;
import com.cambook.db.mapper.CbDriverMapper;
import com.cambook.db.service.ICbDriverService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 司机表：记录司机认证信息/实时位置/接单统计，支持派车功能 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class CbDriverServiceImpl extends ServiceImpl<CbDriverMapper, CbDriver> implements ICbDriverService {

}
