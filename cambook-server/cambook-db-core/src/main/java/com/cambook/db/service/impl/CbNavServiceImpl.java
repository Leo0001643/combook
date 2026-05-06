package com.cambook.db.service.impl;

import com.cambook.db.entity.CbNav;
import com.cambook.db.mapper.CbNavMapper;
import com.cambook.db.service.ICbNavService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * APP/H5 底部导航配置：支持多端动态配置，无需发版调整 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class CbNavServiceImpl extends ServiceImpl<CbNavMapper, CbNav> implements ICbNavService {

}
