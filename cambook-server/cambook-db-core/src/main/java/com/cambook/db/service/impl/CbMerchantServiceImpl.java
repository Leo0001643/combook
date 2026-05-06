package com.cambook.db.service.impl;

import com.cambook.db.entity.CbMerchant;
import com.cambook.db.mapper.CbMerchantMapper;
import com.cambook.db.service.ICbMerchantService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 商户表：多语言名称/地址，含业务类型和特色功能开关 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class CbMerchantServiceImpl extends ServiceImpl<CbMerchantMapper, CbMerchant> implements ICbMerchantService {

}
