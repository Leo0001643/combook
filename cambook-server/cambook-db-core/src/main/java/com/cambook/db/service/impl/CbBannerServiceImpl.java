package com.cambook.db.service.impl;

import com.cambook.db.entity.CbBanner;
import com.cambook.db.mapper.CbBannerMapper;
import com.cambook.db.service.ICbBannerService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * Banner 轮播图：支持多位置、多语言标题、有效期和三种跳转方式 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class CbBannerServiceImpl extends ServiceImpl<CbBannerMapper, CbBanner> implements ICbBannerService {

}
