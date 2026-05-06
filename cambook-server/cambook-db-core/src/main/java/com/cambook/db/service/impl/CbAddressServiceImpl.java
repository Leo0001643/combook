package com.cambook.db.service.impl;

import com.cambook.db.entity.CbAddress;
import com.cambook.db.mapper.CbAddressMapper;
import com.cambook.db.service.ICbAddressService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 用户服务地址表：支持多地址管理，下单时快照至订单 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class CbAddressServiceImpl extends ServiceImpl<CbAddressMapper, CbAddress> implements ICbAddressService {

}
